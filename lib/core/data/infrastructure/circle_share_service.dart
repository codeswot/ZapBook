import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:convert/convert.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';

import 'package:zapbook/core/data/library_file_store.dart';
import 'package:zapbook/core/domain/book_segment_source.dart';
import 'package:zapbook/core/data/infrastructure/blossom_service.dart';
import 'package:zapbook/core/data/infrastructure/group_envelope_service.dart';
import 'package:zapbook/core/domain/entities/app_message.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/data/database/dao/book_key_dao.dart';
import 'package:zapbook/core/models/book_manifest_payload.dart';
import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/core/models/book_download_progress.dart';

typedef _TaskResult = ({
  BookManifestFile? file,
  Object? error,
  StackTrace? stack,
});

typedef UploadOutcome = ({
  BookManifestPayload? manifest,
  Map<String, BookManifestFile> uploaded,
  Object? error,
  StackTrace? stack,
});

typedef _DownloadResult = ({
  Uint8List? bytes,
  Object? error,
  StackTrace? stack,
});

@lazySingleton
class CircleShareService {
  static const kSegmentExt = '.zbfseg';
  static const kSourceExt = '.source';

  CircleShareService(
    this._marmot,
    this._blossom,
    this._fileStore,
    this._envelope,
    this._identity,
    this._bookKeyDao,
  );

  final Marmot _marmot;
  final BlossomService _blossom;
  final LibraryFileStore _fileStore;
  final GroupEnvelopeService _envelope;
  final IdentityLocalDataSource _identity;
  final BookKeyDao _bookKeyDao;
  final _log = logging.Logger('CircleShareService');

  static const kReseedContentType =
      'application/vnd.zapbook.reseed-request+json';
  static const _reseedRequestCooldown = Duration(hours: 1);
  final _lastReseedRequestAt = <String, DateTime>{};

  final _progressController =
      StreamController<BookDownloadProgress>.broadcast();
  Stream<BookDownloadProgress> get onBookDownloadProgress =>
      _progressController.stream;

  static const _reader = ZbfReader();
  static const _segmenter = ZbfSegmenter();

  static const int _transferConcurrency = 4;
  static const String _blobMimeType = 'application/octet-stream';
  static const int _segmentIndexWidth = 4;

  Future<UploadOutcome> uploadBookContent(
    String npub,
    String groupId,
    String circleDirId, {
    Map<String, BookManifestFile> alreadyUploaded = const {},
  }) async {
    final zbf = await _fileStore.zbfFile(circleDirId);
    if (!await zbf.exists()) {
      _log.warning(
        'Cannot upload book content: ZBF file not found for $circleDirId',
      );
      return (
        manifest: null,
        uploaded: <String, BookManifestFile>{},
        error: null,
        stack: null,
      );
    }

    var keys = await _bookKeyDao.getKey(circleDirId);
    if (keys == null) {
      final k = Key.fromSecureRandom(32);
      final i = IV.fromSecureRandom(16);
      keys = (keyHex: hex.encode(k.bytes), ivHex: hex.encode(i.bytes));
      await _bookKeyDao.saveKey(
        nostrGroupId: groupId,
        circleDirId: circleDirId,
        keyHex: keys.keyHex,
        ivHex: keys.ivHex,
      );
    }

    final encrypter = Encrypter(
      AES(Key(Uint8List.fromList(hex.decode(keys.keyHex))), mode: AESMode.cbc),
    );
    final iv = IV(Uint8List.fromList(hex.decode(keys.ivHex)));

    final uploadedFiles = Map<String, BookManifestFile>.from(alreadyUploaded);
    Object? firstError;
    StackTrace? firstStack;

    void recordResult(_TaskResult result, String key) {
      if (result.error != null) {
        firstError ??= result.error;
        firstStack ??= result.stack;
      } else if (result.file != null) {
        uploadedFiles[key] = result.file!;
      }
    }

    final handle = await _reader.open(zbf.path);
    try {
      final window = <Future<MapEntry<String, _TaskResult>>>[];

      final sourcePath = handle.sourceDocumentPath();
      final sourceKey = 'source';
      if (sourcePath != null && !alreadyUploaded.containsKey(sourceKey)) {
        window.add(
          _guard(
            () => _uploadSource(sourcePath, circleDirId, encrypter, iv),
          ).then((r) => MapEntry(sourceKey, r)),
        );
      }

      final segments = <BookManifestSegment>[];

      await for (final segment in _segmenter.segment(handle)) {
        if (firstError != null) break;

        final segmentKey = 'seg_${segment.index}';

        if (alreadyUploaded.containsKey(segmentKey)) {
          segments.add(
            BookManifestSegment(
              index: segment.index,
              file: alreadyUploaded[segmentKey]!,
            ),
          );
          continue;
        }

        window.add(
          _guard(
            () => _uploadBlob(
              segment.bytes,
              circleDirId,
              segment.index,
              encrypter,
              iv,
            ),
          ).then((r) {
            if (r.file != null) {
              segments.add(
                BookManifestSegment(index: segment.index, file: r.file!),
              );
            }
            return MapEntry(segmentKey, r);
          }),
        );
        if (window.length >= _transferConcurrency) {
          final entry = await window.removeAt(0);
          recordResult(entry.value, entry.key);
        }
      }

      while (window.isNotEmpty) {
        final entry = await window.removeAt(0);
        recordResult(entry.value, entry.key);
      }

      if (firstError == null) {
        final manifest = BookManifestPayload(
          circleDirId: circleDirId,
          keyHex: keys.keyHex,
          ivHex: keys.ivHex,
          segments: segments,
          source: uploadedFiles[sourceKey],
        );

        await broadcastManifest(npub, groupId, manifest);

        return (
          manifest: manifest,
          uploaded: uploadedFiles,
          error: null,
          stack: null,
        );
      }
    } finally {
      handle.close();
    }

    return (
      manifest: null,
      uploaded: uploadedFiles,
      error: firstError,
      stack: firstStack,
    );
  }

  Future<BookManifestFile> _uploadSource(
    String sourcePath,
    String circleDirId,
    Encrypter encrypter,
    IV iv,
  ) async {
    final sourceBytes = await File(sourcePath).readAsBytes();
    final encrypted = encrypter.encryptBytes(sourceBytes, iv: iv);

    final url = await _blossom.upload(encrypted.bytes);
    final hash = sha256.convert(encrypted.bytes).toString();

    return BookManifestFile(
      url: url,
      hash: hash,
      filename: '$circleDirId$kSourceExt',
      mimeType: _blobMimeType,
    );
  }

  Future<BookManifestFile> _uploadBlob(
    Uint8List bytes,
    String circleDirId,
    int index,
    Encrypter encrypter,
    IV iv,
  ) async {
    final encrypted = encrypter.encryptBytes(bytes, iv: iv);

    final url = await _blossom.upload(encrypted.bytes);
    final hash = sha256.convert(encrypted.bytes).toString();

    final strIndex = index.toString().padLeft(_segmentIndexWidth, '0');
    return BookManifestFile(
      url: url,
      hash: hash,
      filename: '$circleDirId.seg$strIndex$kSegmentExt',
      mimeType: _blobMimeType,
    );
  }

  Future<void> broadcastManifest(
    String npub,
    String groupId,
    BookManifestPayload manifest,
  ) async {
    final rumor = await buildUnsignedRumor(
      npub: npub,
      content: jsonEncode(manifest.toJson()),
      contentType: AppMessageTypes.bookManifest,
    );
    final event = await _marmot.sendMessage(rumor, groupId);
    await _envelope.publish(event);
  }

  Future<BookManifestPayload?> getLatestManifest(
    String groupId,
    String circleDirId,
  ) async {
    final messages = await _marmot.getMessages(groupId);
    for (final message in messages.reversed) {
      if (message.contentType == AppMessageTypes.bookManifest &&
          message.payloadJson != null) {
        try {
          final payload = BookManifestPayload.fromJson(
            jsonDecode(message.payloadJson!),
          );
          if (payload.circleDirId == circleDirId) {
            return payload;
          }
        } catch (e, st) {
          _log.severe('Failed to parse manifest payload', e, st);
        }
      }
    }
    return null;
  }

  Future<bool> fetchAndDownloadBook(String groupId, String circleDirId) async {
    try {
      final manifest = await getLatestManifest(groupId, circleDirId);

      if (manifest == null) {
        _log.warning('No manifest found in messages for $circleDirId');
        unawaited(_notifyReseedNeeded(groupId, circleDirId));
        return false;
      }

      final ok = await downloadBookContent(circleDirId, groupId, manifest);
      if (!ok) unawaited(_notifyReseedNeeded(groupId, circleDirId));
      return ok;
    } catch (e, st) {
      _log.warning('Failed to fetch manifest for $groupId', e, st);
      unawaited(_notifyReseedNeeded(groupId, circleDirId));
      return false;
    }
  }

  Future<void> _notifyReseedNeeded(String groupId, String circleDirId) async {
    final last = _lastReseedRequestAt[circleDirId];
    if (last != null &&
        DateTime.now().difference(last) < _reseedRequestCooldown) {
      return;
    }
    try {
      final npub = await _identity.readNpub();
      if (npub == null || npub.isEmpty) return;
      _lastReseedRequestAt[circleDirId] = DateTime.now();
      await requestReseed(npub, groupId, circleDirId);
    } on Object catch (error, stack) {
      _log.fine('Reseed notify skipped for $circleDirId: $error\n$stack');
    }
  }

  Future<void> requestReseed(
    String npub,
    String groupId,
    String circleDirId,
  ) async {
    final rumor = await buildUnsignedRumor(
      npub: npub,
      content: jsonEncode({'circleDirId': circleDirId}),
      contentType: kReseedContentType,
    );
    final event = await _marmot.sendMessage(rumor, groupId);
    await _envelope.publish(event);
  }

  Future<List<String>> reseedRequesters(
    String groupId,
    String circleDirId, {
    DateTime? since,
  }) async {
    try {
      final messages = await _marmot.getMessages(groupId);
      final sinceSecs = since == null
          ? 0
          : since.millisecondsSinceEpoch ~/ 1000;

      final requesters = <String>{};
      for (final message in messages) {
        if (message.contentType != kReseedContentType) continue;
        if (message.timestampSecs.toInt() <= sinceSecs) continue;

        final payload = message.payloadJson;
        if (payload == null) continue;
        try {
          final decoded = jsonDecode(payload) as Map<String, dynamic>;
          if (decoded['circleDirId'] == circleDirId) {
            requesters.add(message.senderNpub);
          }
        } on Object catch (_) {
          continue;
        }
      }
      return requesters.toList();
    } on Object catch (error, stack) {
      _log.warning(
        'Failed to read reseed requests for $circleDirId',
        error,
        stack,
      );
      return [];
    }
  }

  Future<bool> downloadBookContent(
    String circleDirId,
    String groupId,
    BookManifestPayload manifest,
  ) async {
    try {
      final encrypter = Encrypter(
        AES(
          Key(Uint8List.fromList(hex.decode(manifest.keyHex))),
          mode: AESMode.cbc,
        ),
      );
      final iv = IV(Uint8List.fromList(hex.decode(manifest.ivHex)));

      Uint8List? sourceBytes;
      if (manifest.source != null) {
        sourceBytes = await downloadAndDecrypt(manifest.source!, encrypter, iv);
      }

      final zbf = await _fileStore.zbfFile(circleDirId);
      await _segmenter.reassembleToDirectory(
        _downloadSegments(manifest.segments, encrypter, iv),
        zbf.path,
        sourceBytes: sourceBytes,
        onSegmentProcessed: () {
          _progressController.add(BookDownloadProgress(circleDirId));
        },
      );
      return true;
    } on Object catch (error, stack) {
      _log.warning(
        'Download book content failed for $circleDirId',
        error,
        stack,
      );
      return false;
    }
  }

  Future<SegmentData?> loadSegment(
    String circleDirId,
    String groupId,
    int segmentIndex,
  ) async {
    try {
      final manifest = await getLatestManifest(groupId, circleDirId);
      if (manifest == null) return null;

      final segment = manifest.segments.firstWhere(
        (s) => s.index == segmentIndex,
      );
      final encrypter = Encrypter(
        AES(
          Key(Uint8List.fromList(hex.decode(manifest.keyHex))),
          mode: AESMode.cbc,
        ),
      );
      final iv = IV(Uint8List.fromList(hex.decode(manifest.ivHex)));

      final zip = await downloadAndDecrypt(segment.file, encrypter, iv);
      final parsed = await _segmenter.parseSegmentAsync(zip);
      if (parsed.pages.isEmpty) return null;
      return SegmentData(
        pageStart: parsed.pages.first.pageNumber - 1,
        pages: parsed.pages,
        assets: parsed.assets,
      );
    } on Object catch (error, stack) {
      _log.warning(
        'Load segment $segmentIndex for $circleDirId failed',
        error,
        stack,
      );
      return null;
    }
  }

  Future<Uint8List> downloadAndDecrypt(
    BookManifestFile file,
    Encrypter encrypter,
    IV iv,
  ) async {
    final blob = await _blossom.download(file.url);
    final decrypted = encrypter.decryptBytes(Encrypted(blob), iv: iv);
    return Uint8List.fromList(decrypted);
  }

  Stream<Uint8List> _downloadSegments(
    List<BookManifestSegment> segments,
    Encrypter encrypter,
    IV iv,
  ) async* {
    final window = <Future<_DownloadResult>>[];
    var next = 0;

    final sorted = List<BookManifestSegment>.from(segments)
      ..sort((a, b) => a.index.compareTo(b.index));

    while (next < sorted.length || window.isNotEmpty) {
      while (window.length < _transferConcurrency && next < sorted.length) {
        window.add(_downloadSafe(sorted[next++].file, encrypter, iv));
      }

      final result = await window.removeAt(0);
      if (result.error != null) {
        Error.throwWithStackTrace(result.error!, result.stack!);
      }
      yield result.bytes!;
    }
  }

  Future<_DownloadResult> _downloadSafe(
    BookManifestFile file,
    Encrypter encrypter,
    IV iv,
  ) async {
    try {
      final bytes = await downloadAndDecrypt(file, encrypter, iv);
      return (bytes: bytes, error: null, stack: null);
    } catch (e, st) {
      return (bytes: null, error: e, stack: st);
    }
  }

  Future<_TaskResult> _guard(Future<BookManifestFile> Function() task) async {
    try {
      final file = await task();
      return (file: file, error: null, stack: null);
    } catch (e, st) {
      return (file: null, error: e, stack: st);
    }
  }
}

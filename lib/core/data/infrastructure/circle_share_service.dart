import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';

import 'package:zapbook/core/data/library_file_store.dart';
import 'package:zapbook/core/domain/book_segment_source.dart';
import 'package:zapbook/core/data/infrastructure/blossom_service.dart';
import 'package:zapbook/core/data/infrastructure/group_envelope_service.dart';
import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/core/models/book_download_progress.dart';

typedef _TaskResult = ({Object? error, StackTrace? stack});

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
  );

  final Marmot _marmot;
  final BlossomService _blossom;
  final LibraryFileStore _fileStore;
  final GroupEnvelopeService _envelope;
  final _log = logging.Logger('CircleShareService');

  final _progressController =
      StreamController<BookDownloadProgress>.broadcast();
  Stream<BookDownloadProgress> get onBookDownloadProgress =>
      _progressController.stream;

  static const _reader = ZbfReader();
  static const _segmenter = ZbfSegmenter();

  static const int _transferConcurrency = 4;
  static const int _fetchMaxAttempts = 10;
  static const Duration _fetchRetryDelay = Duration(seconds: 2);
  static const String _blobMimeType = 'application/octet-stream';
  static const int _segmentIndexWidth = 4;

  static final RegExp _segmentIndexPattern = RegExp(
    r'\.seg(\d+)' + RegExp.escape(kSegmentExt) + r'$',
  );

  Future<void> uploadBookContent(
    String npub,
    String groupId,
    String circleDirId,
  ) async {
    final zbf = await _fileStore.zbfFile(circleDirId);
    if (!await zbf.exists()) {
      _log.warning(
        'Cannot upload book content: ZBF file not found for $circleDirId',
      );
      return;
    }

    final handle = await _reader.open(zbf.path);
    try {
      final window = <Future<_TaskResult>>[];

      final sourcePath = handle.sourceDocumentPath();
      if (sourcePath != null) {
        window.add(
          _guard(() => _uploadSource(npub, groupId, circleDirId, sourcePath)),
        );
      }

      await for (final segment in _segmenter.segment(handle)) {
        final index = segment.index.toString().padLeft(_segmentIndexWidth, '0');
        window.add(
          _guard(
            () => _uploadBlob(
              npub,
              groupId,
              segment.bytes,
              _blobMimeType,
              '$circleDirId.seg$index$kSegmentExt',
            ),
          ),
        );
        if (window.length >= _transferConcurrency) {
          await _drainOne(window);
        }
      }

      while (window.isNotEmpty) {
        await _drainOne(window);
      }
    } finally {
      handle.close();
    }
  }

  Future<bool> fetchAndDownloadBook(String groupId, String circleDirId) async {
    try {
      List<MarmotMediaRef> segments = [];
      MarmotMediaRef? sourceRef;

      for (var attempt = 0; attempt < _fetchMaxAttempts; attempt++) {
        final found = await _collectMediaRefs(groupId, circleDirId);
        segments = found.segments;
        sourceRef = found.sourceRef;
        if (found.complete) break;

        if (attempt < _fetchMaxAttempts - 1) {
          await Future.delayed(_fetchRetryDelay);
        }
      }

      if (segments.isEmpty) {
        _log.warning('No segment assets found in messages for $circleDirId');
        return false;
      }

      segments.sort((a, b) => a.filename.compareTo(b.filename));

      return downloadBookContent(circleDirId, groupId, segments, sourceRef);
    } catch (e, st) {
      _log.warning('Failed to fetch messages for $groupId', e, st);
      return false;
    }
  }

  Future<bool> downloadBookContent(
    String circleDirId,
    String groupId,
    List<MarmotMediaRef> segmentRefs,
    MarmotMediaRef? sourceRef,
  ) async {
    try {
      Uint8List? sourceBytes;
      if (sourceRef != null) {
        sourceBytes = await downloadAndDecrypt(groupId, sourceRef);
      }

      final zbf = await _fileStore.zbfFile(circleDirId);
      await _segmenter.reassembleToDirectory(
        _downloadSegments(groupId, segmentRefs),
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
    MarmotMediaRef ref,
  ) async {
    try {
      final zip = await downloadAndDecrypt(groupId, ref);
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
    String groupId,
    MarmotMediaRef ref,
  ) async {
    final blob = await _blossom.download(ref.url);
    return _marmot.decryptMedia(
      groupId,
      blob,
      MediaRefInput(
        url: ref.url,
        originalHash: ref.originalHash,
        mimeType: ref.mimeType,
        filename: ref.filename,
        schemeVersion: ref.schemeVersion,
        nonce: ref.nonce,
      ),
    );
  }

  Future<
    ({List<MarmotMediaRef> segments, MarmotMediaRef? sourceRef, bool complete})
  >
  _collectMediaRefs(String groupId, String circleDirId) async {
    final messages = await _marmot.getMessages(groupId);
    final segmentsMap = <String, MarmotMediaRef>{};
    MarmotMediaRef? sourceRef;
    var maxSegmentIndex = -1;

    bool isComplete() =>
        maxSegmentIndex != -1 &&
        segmentsMap.length == maxSegmentIndex + 1 &&
        sourceRef != null;

    for (final message in messages.reversed) {
      for (final media in message.media) {
        if (!media.filename.startsWith(circleDirId)) continue;

        if (media.filename.endsWith(kSourceExt)) {
          sourceRef ??= media;
        } else if (media.filename.endsWith(kSegmentExt) &&
            !segmentsMap.containsKey(media.filename)) {
          segmentsMap[media.filename] = media;
          final match = _segmentIndexPattern.firstMatch(media.filename);
          if (match != null) {
            final index = int.parse(match.group(1)!);
            if (index > maxSegmentIndex) {
              maxSegmentIndex = index;
            }
          }
        }
      }

      if (isComplete()) break;
    }

    return (
      segments: segmentsMap.values.toList(),
      sourceRef: sourceRef,
      complete: isComplete(),
    );
  }

  Future<void> _uploadSource(
    String npub,
    String groupId,
    String circleDirId,
    String sourcePath,
  ) async {
    final sourceBytes = await File(sourcePath).readAsBytes();
    await _uploadBlob(
      npub,
      groupId,
      sourceBytes,
      _blobMimeType,
      '$circleDirId$kSourceExt',
    );
  }

  Future<void> _uploadBlob(
    String npub,
    String groupId,
    Uint8List bytes,
    String mimeType,
    String filename,
  ) async {
    final enc = await _marmot.encryptMedia(groupId, bytes, mimeType, filename);
    final url = await _blossom.upload(enc.encryptedData);
    final rumor = await _marmot.buildMediaRumor(
      npub: npub,
      groupId: groupId,
      caption: '',
      url: url,
      originalHash: enc.originalHash,
      mimeType: enc.mimeType,
      filename: enc.filename,
      nonce: enc.nonce,
      blurhash: enc.blurhash,
      thumbhash: enc.thumbhash,
      dimensionsWidth: enc.dimensionsWidth,
      dimensionsHeight: enc.dimensionsHeight,
    );
    final event = await _marmot.sendMessage(rumor, groupId);
    await _envelope.publish(event);
  }

  Stream<Uint8List> _downloadSegments(
    String groupId,
    List<MarmotMediaRef> refs,
  ) async* {
    final window = <Future<_DownloadResult>>[];
    var next = 0;

    while (next < refs.length || window.isNotEmpty) {
      while (window.length < _transferConcurrency && next < refs.length) {
        window.add(_downloadSafe(groupId, refs[next++]));
      }

      final result = await window.removeAt(0);
      if (result.error != null) {
        Error.throwWithStackTrace(result.error!, result.stack!);
      }
      yield result.bytes!;
    }
  }

  Future<_DownloadResult> _downloadSafe(
    String groupId,
    MarmotMediaRef ref,
  ) async {
    try {
      final bytes = await downloadAndDecrypt(groupId, ref);
      return (bytes: bytes, error: null, stack: null);
    } catch (e, st) {
      return (bytes: null, error: e, stack: st);
    }
  }

  Future<_TaskResult> _guard(Future<void> Function() task) async {
    try {
      await task();
      return (error: null, stack: null);
    } catch (e, st) {
      return (error: e, stack: st);
    }
  }

  Future<void> _drainOne(List<Future<_TaskResult>> window) async {
    final result = await window.removeAt(0);
    if (result.error != null) {
      Error.throwWithStackTrace(result.error!, result.stack!);
    }
  }
}

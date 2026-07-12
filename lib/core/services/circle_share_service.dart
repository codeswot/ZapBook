import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';

import 'package:zapbook/core/data/library_file_store.dart';
import 'package:zapbook/core/domain/book_segment_source.dart';
import 'package:zapbook/core/services/blossom_service.dart';
import 'package:zapbook/core/services/group_envelope_service.dart';
import 'package:zapbook/zbf/zbf.dart';

class BookDownloadProgress {
  final String circleDirId;
  const BookDownloadProgress(this.circleDirId);
}

@lazySingleton
class CircleShareService {
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

  Future<void> uploadBookContent(
    String npub,
    String groupId,
    String circleDirId,
  ) async {
    final zbf = await _fileStore.zbfFile(circleDirId);
    if (!zbf.existsSync()) {
      _log.warning(
        'Cannot upload book content: ZBF file not found for $circleDirId',
      );
      return;
    }

    final handle = await _reader.open(zbf.path);
    try {
      final sourcePath = handle.sourceDocumentPath();
      if (sourcePath != null) {
        final sourceBytes = File(sourcePath).readAsBytesSync();
        await _uploadBlob(
          npub,
          groupId,
          sourceBytes,
          'application/octet-stream',
          '$circleDirId.source',
        );
      }

      final segments = await _segmenter.segment(handle).toList();
      for (var i = 0; i < segments.length; i += 4) {
        final batch = segments.skip(i).take(4);
        await Future.wait(
          batch.map((segment) {
            final index = segment.index.toString().padLeft(4, '0');
            return _uploadBlob(
              npub,
              groupId,
              segment.bytes,
              'application/octet-stream',
              '$circleDirId.seg$index.zbfseg',
            );
          }),
        );
      }
    } finally {
      handle.close();
    }
  }

  Future<bool> fetchAndDownloadBook(String groupId, String circleDirId) async {
    try {
      final messages = await _marmot.getMessages(groupId);
      final segmentsMap = <String, MarmotMediaRef>{};
      MarmotMediaRef? sourceRef;

      int maxSegmentIndex = -1;

      for (final message in messages.reversed) {
        for (final media in message.media) {
          if (!media.filename.startsWith(circleDirId)) continue;

          if (media.filename.endsWith('.source')) {
            sourceRef ??= media;
          } else if (media.filename.endsWith('.zbfseg')) {
            if (segmentsMap.putIfAbsent(media.filename, () => media) == media) {
              final match = RegExp(
                r'\.seg(\d+)\.zbfseg$',
              ).firstMatch(media.filename);
              if (match != null) {
                final idx = int.parse(match.group(1)!);
                if (idx > maxSegmentIndex) {
                  maxSegmentIndex = idx;
                }
              }
            }
          }
        }

        if (maxSegmentIndex != -1 &&
            segmentsMap.length == maxSegmentIndex + 1 &&
            sourceRef != null) {
          break;
        }
      }

      final segments = segmentsMap.values.toList();
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
    _envelope.publish(event);
  }

  Stream<Uint8List> _downloadSegments(
    String groupId,
    List<MarmotMediaRef> refs,
  ) async* {
    for (var i = 0; i < refs.length; i += 4) {
      final batch = refs.skip(i).take(4);
      final downloaded = await Future.wait(
        batch.map((ref) => downloadAndDecrypt(groupId, ref)),
      );
      for (final bytes in downloaded) {
        yield bytes;
      }
    }
  }
}

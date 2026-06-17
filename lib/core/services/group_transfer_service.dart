import 'dart:async';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';

import 'package:zapbook/core/data/library_file_store.dart';
import 'package:zapbook/core/domain/book_segment_source.dart';
import 'package:zapbook/core/services/blossom_service.dart';
import 'package:zapbook/core/services/group_envelope_service.dart';
import 'package:zapbook/zbf/zbf.dart';

@lazySingleton
class GroupTransferService {
  GroupTransferService(
    this._marmot,
    this._blossom,
    this._fileStore,
    this._envelope,
  );

  final Marmot _marmot;
  final BlossomService _blossom;
  final LibraryFileStore _fileStore;
  final GroupEnvelopeService _envelope;
  final _log = logging.Logger('GroupTransferService');

  static const _reader = ZbfReader();
  static const _segmenter = ZbfSegmenter();

  Future<void> uploadBookContent(
    String npub,
    String groupId,
    String bookId,
  ) async {
    final zbf = await _fileStore.zbfFile(bookId);
    if (!zbf.existsSync()) return;

    final handle = await _reader.open(zbf.path);
    try {
      final source = handle.sourceDocument();
      if (source != null) {
        await _uploadBlob(
          npub,
          groupId,
          source,
          'application/octet-stream',
          '$bookId.source',
        );
      }

      await for (final segment in _segmenter.segment(handle)) {
        final index = segment.index.toString().padLeft(4, '0');
        await _uploadBlob(
          npub,
          groupId,
          segment.bytes,
          'application/octet-stream',
          '$bookId.seg$index.zbfseg',
        );
      }
    } finally {
      handle.close();
    }
  }

  Future<void> uploadGroupCover(String groupId, Uint8List coverBytes) async {
    final prep = await Marmot.prepareGroupImage(coverBytes, 'image/jpeg');
    await _blossom.upload(prep.encryptedData, mimeType: 'image/jpeg');
    final commit = await _marmot.setGroupImage(
      groupId,
      imageHash: prep.imageHash,
      imageKey: prep.imageKey,
      imageNonce: prep.imageNonce,
      imageUploadKey: prep.imageUploadKey,
    );
    _envelope.publish(commit);
  }

  Future<String?> hydrateCover(
    String bookId,
    MarmotGroup? group, {
    List<int>? imageHash,
    List<int>? imageKey,
    List<int>? imageNonce,
  }) async {
    final existing = await _fileStore.coverPathIfExists(bookId);
    if (existing != null) return existing;

    if (group == null) return null;
    final hash = imageHash ?? group.imageHash;
    final key = imageKey ?? group.imageKey;
    final nonce = imageNonce ?? group.imageNonce;
    if (hash == null || key == null || nonce == null) return null;

    final blob = await _blossom.download(
      '${BlossomService.servers.first}/${_hex(hash)}',
    );
    final bytes = await Marmot.decryptGroupImage(
      encryptedData: blob,
      imageHash: hash as Uint8List,
      imageKey: key as Uint8List,
      imageNonce: nonce as Uint8List,
    );
    return _fileStore.writeCover(bookId, bytes);
  }

  Future<bool> downloadBookContent(
    String bookId,
    String groupId,
    List<MarmotMediaRef> segmentRefs,
    MarmotMediaRef? sourceRef,
  ) async {
    try {
      Uint8List? sourceBytes;
      if (sourceRef != null) {
        sourceBytes = await downloadAndDecrypt(groupId, sourceRef);
      }

      final zbf = await _fileStore.zbfFile(bookId);
      await _segmenter.reassembleToFile(
        _downloadSegments(groupId, segmentRefs),
        zbf.path,
        sourceBytes: sourceBytes,
      );
      return true;
    } on Object catch (error, stack) {
      _log.warning('Download book content failed for $bookId', error, stack);
      return false;
    }
  }

  Future<SegmentData?> loadSegment(
    String bookId,
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
        'Load segment $segmentIndex for $bookId failed',
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
    for (final ref in refs) {
      yield await downloadAndDecrypt(groupId, ref);
    }
  }

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

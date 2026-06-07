import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';

import 'package:zapbook/core/data/library_file_store.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/blossom_service.dart';
import 'package:zapbook/core/services/nostr_service.dart';
import 'package:zapbook/features/library/data/marmot/book_payloads.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/zbf/zbf.dart';

@lazySingleton
class BookGroupDatasource {
  BookGroupDatasource(
    this._marmot,
    this._blossom,
    this._fileStore,
    this._identity,
    this._ndk,
  );

  final Marmot _marmot;
  final BlossomService _blossom;
  final LibraryFileStore _fileStore;
  final IdentityLocalDataSource _identity;
  final Ndk _ndk;

  final _log = logging.Logger('BookGroupDatasource');
  final Map<String, String> _groupIdByBookId = {};

  static const _groupPrefix = 'zapbook-book-';
  static const _groupDescription = 'ZapBook personal library book';
  static const _relays = NostrService.broadcastRelays;

  String _groupName(String bookId) => '$_groupPrefix$bookId';

  Future<List<LibraryBook>> loadLibrary() async {
    final groups = await _marmot.listGroups();
    final books = <LibraryBook>[];
    for (final group in groups) {
      if (!group.name.startsWith(_groupPrefix)) continue;
      final book = await _reconstruct(group.id);
      if (book == null) continue;
      _groupIdByBookId[book.id] = group.id;
      books.add(book);
    }
    return books;
  }

  Future<LibraryBook?> getBook(String bookId) async {
    final groupId = await _resolveGroupId(bookId);
    if (groupId == null) return null;
    return _reconstruct(groupId);
  }

  Future<LibraryBook> addBook(
    ZbfBook book, {
    String? contentHash,
  }) {
    final manifest = book.manifest;
    final cover = book.assets[manifest.coverAsset];
    final original = book.assets[AssetNaming.sourceDocument];
    return _create(
      manifest: manifest,
      coverBytes: cover == null ? null : Uint8List.fromList(cover),
      originalBytes: original == null ? null : Uint8List.fromList(original),
      contentHash: contentHash,
    );
  }

  Future<LibraryBook> importExisting({
    required BookManifest manifest,
    Uint8List? coverBytes,
    Uint8List? originalBytes,
    String? contentHash,
  }) =>
      _create(
        manifest: manifest,
        coverBytes: coverBytes,
        originalBytes: originalBytes,
        contentHash: contentHash,
      );

  Future<LibraryBook> _create({
    required BookManifest manifest,
    Uint8List? coverBytes,
    Uint8List? originalBytes,
    String? contentHash,
  }) async {
    final npub = await _requireNpub();
    final bookId = manifest.id;

    final result = await _marmot.createGroup(
      npub,
      CreateGroupParams(
        name: _groupName(bookId),
        description: _groupDescription,
        relayUrls: _relays,
        memberKeyPackageEventJsons: const [],
      ),
    );
    final groupId = result.group.id;
    _groupIdByBookId[bookId] = groupId;

    final meta = _metaFromManifest(manifest, contentHash: contentHash);
    final metaEvent = await _marmot.sendStructured(npub, groupId, meta.toJson());
    _publish(metaEvent);

    if (coverBytes != null) {
      await _fileStore.writeCover(bookId, coverBytes);
    }

    unawaited(
      _uploadDurableBlobs(groupId, bookId, manifest, coverBytes, originalBytes),
    );

    return _toLibraryBook(meta, lastReadAtMs: null);
  }

  Future<void> sendMeta(String bookId, BookMetaPayload meta) async {
    final groupId = await _resolveGroupId(bookId);
    if (groupId == null) return;
    final npub = await _requireNpub();
    final event = await _marmot.sendStructured(npub, groupId, meta.toJson());
    _publish(event);
  }

  Future<void> sendProgress(String bookId, DateTime lastReadAt) async {
    final groupId = await _resolveGroupId(bookId);
    if (groupId == null) return;
    final npub = await _requireNpub();
    final payload = BookProgressPayload(
      bookId: bookId,
      lastReadAtMs: lastReadAt.millisecondsSinceEpoch,
    );
    final event = await _marmot.sendStructured(npub, groupId, payload.toJson());
    _publish(event);
  }

  Future<BookMetaPayload?> currentMeta(String bookId) async {
    final groupId = await _resolveGroupId(bookId);
    if (groupId == null) return null;
    return _latestMeta(await _marmot.getMessages(groupId));
  }

  Future<void> deleteBook(String bookId) async {
    final groupId = await _resolveGroupId(bookId);
    if (groupId != null) {
      await _marmot.deleteGroup(groupId);
    }
    _groupIdByBookId.remove(bookId);
    await _fileStore.deleteBook(bookId);
  }

  Future<LibraryBook?> _reconstruct(String groupId) async {
    final messages = await _marmot.getMessages(groupId);
    final meta = _latestMeta(messages);
    if (meta == null) return null;
    final progress = _latestProgress(messages);
    return _toLibraryBook(meta, lastReadAtMs: progress?.lastReadAtMs);
  }

  BookMetaPayload? _latestMeta(List<MarmotMessage> messages) {
    BookMetaPayload? latest;
    var latestTs = -1;
    for (final message in messages) {
      final json = _payload(message);
      if (json == null || json['type'] != BookMessageType.meta) continue;
      final ts = message.timestampSecs.toInt();
      if (ts >= latestTs) {
        latestTs = ts;
        latest = BookMetaPayload.fromJson(json);
      }
    }
    return latest;
  }

  BookProgressPayload? _latestProgress(List<MarmotMessage> messages) {
    BookProgressPayload? latest;
    var latestMs = -1;
    for (final message in messages) {
      final json = _payload(message);
      if (json == null || json['type'] != BookMessageType.progress) continue;
      final payload = BookProgressPayload.fromJson(json);
      if (payload.lastReadAtMs >= latestMs) {
        latestMs = payload.lastReadAtMs;
        latest = payload;
      }
    }
    return latest;
  }

  Map<String, dynamic>? _payload(MarmotMessage message) {
    final raw = message.payloadJson;
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on Object {
      return null;
    }
  }

  Future<LibraryBook> _toLibraryBook(
    BookMetaPayload meta, {
    required int? lastReadAtMs,
  }) async {
    final zbf = await _fileStore.zbfFile(meta.bookId);
    final coverPath = await _fileStore.coverPathIfExists(meta.bookId);
    return LibraryBook(
      id: meta.bookId,
      title: meta.title,
      author: meta.author,
      genre: meta.genre,
      sourceFormat: BookSourceFormat.fromWire(meta.sourceFormat),
      pageCount: meta.pageCount,
      chapterCount: meta.chapterCount,
      zbfPath: zbf.path,
      coverPath: coverPath,
      needsAiProcessing: meta.needsAiProcessing,
      zbfVersion: meta.zbfVersion,
      createdAt: DateTime.fromMillisecondsSinceEpoch(meta.createdAtMs),
      addedAt: DateTime.fromMillisecondsSinceEpoch(meta.addedAtMs),
      lastOpenedAt: lastReadAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastReadAtMs),
      contentHash: meta.contentHash,
    );
  }

  BookMetaPayload _metaFromManifest(
    BookManifest manifest, {
    String? contentHash,
  }) {
    return BookMetaPayload(
      bookId: manifest.id,
      title: manifest.title,
      author: manifest.author,
      genre: manifest.genre,
      contentHash: contentHash,
      sourceFormat: manifest.sourceFormat.wireValue,
      pageCount: manifest.pageCount,
      chapterCount: manifest.chapterCount,
      zbfVersion: manifest.zbfVersion,
      needsAiProcessing: manifest.needsAiProcessing,
      createdAtMs: manifest.createdAt.millisecondsSinceEpoch,
      addedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _uploadDurableBlobs(
    String groupId,
    String bookId,
    BookManifest manifest,
    Uint8List? coverBytes,
    Uint8List? originalBytes,
  ) async {
    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return;

    if (coverBytes != null) {
      await _uploadBlob(
        npub,
        groupId,
        coverBytes,
        _mimeForCover(manifest.coverAsset),
        '$bookId.cover.${_extOf(manifest.coverAsset)}',
      );
    }

    if (originalBytes != null) {
      await _uploadBlob(
        npub,
        groupId,
        originalBytes,
        _mimeForFormat(manifest.sourceFormat),
        '$bookId.${manifest.sourceFormat.wireValue}',
      );
    }
  }

  Future<void> _uploadBlob(
    String npub,
    String groupId,
    Uint8List bytes,
    String mimeType,
    String filename,
  ) async {
    try {
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
      _publish(event);
      _log.info('Uploaded blob $filename');
    } on Object catch (error, stack) {
      _log.warning('Blob upload failed for $filename', error, stack);
    }
  }

  void _publish(String eventJson) {
    try {
      _ndk.broadcast.broadcast(
        nostrEvent: _toNip01Event(eventJson),
        specificRelays: _relays,
      );
    } on Object catch (error, stack) {
      _log.warning('Relay publish failed', error, stack);
    }
  }

  Nip01Event _toNip01Event(String eventJson) {
    final map = jsonDecode(eventJson) as Map<String, dynamic>;
    final tags = (map['tags'] as List)
        .map((tag) => (tag as List).map((e) => e.toString()).toList())
        .toList();
    return Nip01Event(
      id: map['id'] as String,
      pubKey: map['pubkey'] as String,
      kind: (map['kind'] as num).toInt(),
      tags: tags,
      content: map['content'] as String,
      sig: map['sig'] as String?,
      createdAt: (map['created_at'] as num).toInt(),
    );
  }

  Future<String?> _resolveGroupId(String bookId) async {
    final cached = _groupIdByBookId[bookId];
    if (cached != null) return cached;
    final name = _groupName(bookId);
    final groups = await _marmot.listGroups();
    for (final group in groups) {
      if (group.name == name) {
        _groupIdByBookId[bookId] = group.id;
        return group.id;
      }
    }
    return null;
  }

  Future<String> _requireNpub() async {
    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) {
      throw StateError('No identity. Sign in before using the library.');
    }
    return npub;
  }

  String _extOf(String assetName) {
    final dot = assetName.lastIndexOf('.');
    return dot == -1 ? 'png' : assetName.substring(dot + 1);
  }

  String _mimeForCover(String assetName) {
    return assetName.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';
  }

  String _mimeForFormat(BookSourceFormat format) {
    switch (format) {
      case BookSourceFormat.pdf:
        return 'application/pdf';
      case BookSourceFormat.docx:
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case BookSourceFormat.epub:
        return 'application/epub+zip';
      case BookSourceFormat.txt:
        return 'text/plain';
    }
  }
}

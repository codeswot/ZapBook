import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';

import 'package:zapbook/core/data/library_file_store.dart';
import 'package:zapbook/core/domain/book_segment_source.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/blossom_service.dart';
import 'package:zapbook/core/services/key_package_service.dart';
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
    this._keyPackages,
    this._reader,
  );

  final Marmot _marmot;
  final BlossomService _blossom;
  final LibraryFileStore _fileStore;
  final IdentityLocalDataSource _identity;
  final Ndk _ndk;
  final KeyPackageService _keyPackages;
  final ZbfReader _reader;

  final _segmenter = const ZbfSegmenter();
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
      books.add(book.copyWith(memberCount: group.memberCount));
    }
    return books;
  }

  Future<LibraryBook?> getBook(String bookId) async {
    final groupId = await _resolveGroupId(bookId);
    if (groupId == null) return null;
    return _reconstruct(groupId);
  }

  Future<LibraryBook> addBook(ZbfBook book, {String? contentHash}) {
    final manifest = book.manifest;
    final cover = book.assets[manifest.coverAsset];
    return _create(
      manifest: manifest,
      coverBytes: cover == null ? null : Uint8List.fromList(cover),
      contentHash: contentHash,
    );
  }

  Future<LibraryBook> importExisting({
    required BookManifest manifest,
    Uint8List? coverBytes,
    String? contentHash,
  }) => _create(
    manifest: manifest,
    coverBytes: coverBytes,
    contentHash: contentHash,
  );

  Future<LibraryBook> _create({
    required BookManifest manifest,
    Uint8List? coverBytes,
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
    final metaEvent = await _marmot.sendStructured(
      npub,
      groupId,
      meta.toJson(),
    );
    _publish(metaEvent);

    if (coverBytes != null) {
      await _fileStore.writeCover(bookId, coverBytes);
      await _setGroupCover(groupId, coverBytes);
    }

    return _toLibraryBook(meta, lastReadAtMs: null);
  }

  Future<void> _setGroupCover(String groupId, Uint8List coverBytes) async {
    try {
      final prep = await Marmot.prepareGroupImage(coverBytes, 'image/jpeg');
      await _blossom.upload(prep.encryptedData, mimeType: 'image/jpeg');
      final commit = await _marmot.setGroupImage(
        groupId,
        imageHash: prep.imageHash,
        imageKey: prep.imageKey,
        imageNonce: prep.imageNonce,
        imageUploadKey: prep.imageUploadKey,
      );
      _publish(commit);
    } on Object catch (error, stack) {
      _log.warning('Set group cover failed', error, stack);
    }
  }

  Future<String?> hydrateCover(String bookId) async {
    final existing = await _fileStore.coverPathIfExists(bookId);
    if (existing != null) return existing;

    var group = await _group(bookId);
    if (group == null) return null;
    if (group.imageHash == null) {
      await _ensureMessages(group.id, group.nostrGroupId);
      group = await _group(bookId);
    }
    final hash = group?.imageHash;
    final key = group?.imageKey;
    final nonce = group?.imageNonce;
    if (group == null || hash == null || key == null || nonce == null) {
      return null;
    }
    try {
      final blob = await _blossom.download(
        '${BlossomService.servers.first}/${_hex(hash)}',
      );
      final bytes = await Marmot.decryptGroupImage(
        encryptedData: blob,
        imageHash: hash,
        imageKey: key,
        imageNonce: nonce,
      );
      return _fileStore.writeCover(bookId, bytes);
    } on Object catch (error, stack) {
      _log.warning('Hydrate cover failed for $bookId', error, stack);
      return null;
    }
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

  Future<void> shareBook(String bookId, String memberNpub) =>
      shareBookWith(bookId, [memberNpub]);

  Future<void> shareBookWith(String bookId, List<String> memberNpubs) async {
    final groupId = await _resolveGroupId(bookId);
    if (groupId == null) {
      throw StateError('Book not found: $bookId');
    }

    var added = 0;
    for (final memberNpub in memberNpubs) {
      final keyPackage = await _keyPackages.fetchKeyPackage(memberNpub);
      if (keyPackage == null) {
        _log.warning('No key package for $memberNpub — skipped');
        continue;
      }
      final change = await _marmot.addMember(groupId, keyPackage);
      _publish(change.evolutionEventJson);

      final recipientHex = await MarmotIdentity.pubkeyHexFromNpub(memberNpub);
      for (final rumor in change.welcomeRumors) {
        await _giftWrapAndPublish(rumor, recipientHex);
      }
      added++;
    }

    if (added == 0) return;

    final meta = await currentMeta(bookId);
    if (meta != null) {
      await sendMeta(bookId, meta);
    }
    await _uploadContent(groupId, bookId);
  }

  Future<List<MarmotMember>> members(String bookId) async {
    final groupId = await _resolveGroupId(bookId);
    if (groupId == null) return const [];
    return _marmot.getMembers(groupId);
  }

  Future<List<String>> adminNpubs(String bookId) async {
    final groupId = await _resolveGroupId(bookId);
    if (groupId == null) return const [];
    final groups = await _marmot.listGroups();
    for (final g in groups) {
      if (g.id == groupId) return g.adminNpubs;
    }
    return const [];
  }

  Future<void> removeMember(String bookId, String memberNpub) async {
    final groupId = await _resolveGroupId(bookId);
    if (groupId == null) return;
    final change = await _marmot.removeMember(groupId, memberNpub);
    _publish(change.evolutionEventJson);
  }

  Future<void> _giftWrapAndPublish(
    String rumorJson,
    String recipientHex,
  ) async {
    try {
      final rumor = _toNip01Event(rumorJson);
      final wrap = await _ndk.giftWrap.toGiftWrap(
        rumor: rumor,
        recipientPubkey: recipientHex,
      );
      _ndk.broadcast.broadcast(nostrEvent: wrap, specificRelays: _relays);
    } on Object catch (error, stack) {
      _log.warning('Gift-wrap welcome failed', error, stack);
    }
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

  Future<void> _uploadContent(String groupId, String bookId) async {
    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return;

    final zbf = await _fileStore.zbfFile(bookId);
    if (!zbf.existsSync()) return;

    final handle = await _reader.open(zbf.path);

    final source = handle.sourceDocument();
    if (source != null) {
      await _uploadBlob(npub, groupId, source, 'application/octet-stream', '$bookId.source');
    }

    for (final segment in _segmenter.segment(handle)) {
      final index = segment.index.toString().padLeft(4, '0');
      await _uploadBlob(
        npub,
        groupId,
        segment.bytes,
        'application/octet-stream',
        '$bookId.seg$index.zbfseg',
      );
    }
  }

  Future<bool> downloadBookContent(String bookId) async {
    final group = await _group(bookId);
    if (group == null) return false;
    try {
      await _ensureMessages(group.id, group.nostrGroupId);
      final messages = await _marmot.getMessages(group.id);
      final segmentRefs = _latestSegmentRefs(messages);
      if (segmentRefs.isEmpty) return false;

      final zips = <Uint8List>[];
      for (final ref in segmentRefs) {
        zips.add(await _downloadAndDecrypt(group.id, ref));
      }

      final sourceRef = _latestMediaRef(messages, contains: '.source');
      Uint8List? sourceBytes;
      if (sourceRef != null) {
        sourceBytes = await _downloadAndDecrypt(group.id, sourceRef);
      }

      final zbfBytes = _segmenter.reassemble(zips, sourceBytes: sourceBytes);
      await _fileStore.writeZbf(bookId, zbfBytes);
      return true;
    } on Object catch (error, stack) {
      _log.warning('Download book content failed for $bookId', error, stack);
      return false;
    }
  }

  Future<SegmentData?> loadSegment(String bookId, int segmentIndex) async {
    final group = await _group(bookId);
    if (group == null) return null;
    try {
      await _ensureMessages(group.id, group.nostrGroupId);
      final messages = await _marmot.getMessages(group.id);
      final index = segmentIndex.toString().padLeft(4, '0');
      final ref = _latestMediaRef(messages, contains: '.seg$index.zbfseg');
      if (ref == null) return null;

      final zip = await _downloadAndDecrypt(group.id, ref);
      final parsed = _segmenter.parseSegment(zip);
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

  List<MarmotMediaRef> _latestSegmentRefs(List<MarmotMessage> messages) {
    final latestByName = <String, ({int ts, MarmotMediaRef ref})>{};
    for (final message in messages) {
      final ts = message.timestampSecs.toInt();
      for (final ref in message.media) {
        if (!ref.filename.contains('.seg')) continue;
        final existing = latestByName[ref.filename];
        if (existing == null || ts >= existing.ts) {
          latestByName[ref.filename] = (ts: ts, ref: ref);
        }
      }
    }
    final refs = latestByName.values.map((entry) => entry.ref).toList();
    refs.sort((a, b) => a.filename.compareTo(b.filename));
    return refs;
  }

  MarmotMediaRef? _latestMediaRef(
    List<MarmotMessage> messages, {
    String? contains,
  }) {
    MarmotMediaRef? latest;
    var latestTs = -1;
    for (final message in messages) {
      final ts = message.timestampSecs.toInt();
      for (final ref in message.media) {
        if (contains != null &&
            ref.filename.contains(contains) &&
            ts >= latestTs) {
          latestTs = ts;
          latest = ref;
        }
      }
    }
    return latest;
  }

  Future<Uint8List> _downloadAndDecrypt(
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
    try {
      final enc = await _marmot.encryptMedia(
        groupId,
        bytes,
        mimeType,
        filename,
      );
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
      id: map['id'] as String?,
      pubKey: map['pubkey'] as String,
      kind: (map['kind'] as num).toInt(),
      tags: tags,
      content: map['content'] as String,
      sig: map['sig'] as String?,
      createdAt: (map['created_at'] as num).toInt(),
    );
  }

  Future<MarmotGroup?> _group(String bookId) async {
    final groupId = await _resolveGroupId(bookId);
    if (groupId == null) return null;
    for (final group in await _marmot.listGroups()) {
      if (group.id == groupId) return group;
    }
    return null;
  }

  final Set<String> _caughtUp = {};

  Future<void> _ensureMessages(String groupId, String nostrGroupId) async {
    if (_caughtUp.contains(groupId)) return;
    try {
      final events = await _ndk.requests
          .query(
            filter: Filter(
              kinds: const [445],
              tags: {
                '#h': [nostrGroupId],
              },
            ),
            explicitRelays: _relays,
          )
          .future;
      for (final event in events) {
        try {
          await _marmot.processIncoming(_eventToJson(event));
        } on Object catch (_) {}
      }
      _caughtUp.add(groupId);
    } on Object catch (error, stack) {
      _log.warning('Catch-up fetch failed for $groupId', error, stack);
    }
  }

  String _eventToJson(Nip01Event event) => jsonEncode({
    'id': event.id,
    'pubkey': event.pubKey,
    'created_at': event.createdAt,
    'kind': event.kind,
    'tags': event.tags,
    'content': event.content,
    'sig': event.sig,
  });

  String _hex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

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
}

import 'dart:async';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';

import 'package:zapbook/core/extensions/nip01_event_extension.dart';
import 'package:zapbook/core/domain/book_group_naming.dart';
import 'package:zapbook/core/services/decoded_message_cache.dart';
import 'package:zapbook/core/data/library_file_store.dart';
import 'package:zapbook/core/domain/book_segment_source.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/group_envelope_service.dart';
import 'package:zapbook/core/services/group_transfer_service.dart';
import 'package:zapbook/core/services/key_package_service.dart';
import 'package:zapbook/core/services/nostr_service.dart';
import 'package:zapbook/features/library/data/marmot/book_payloads.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/domain/entities/share_skip.dart';
import 'package:zapbook/zbf/zbf.dart';

@lazySingleton
class BookGroupDatasource {
  BookGroupDatasource(
    this._marmot,
    this._fileStore,
    this._identity,
    this._ndk,
    this._keyPackages,
    this._cache,
    this._transfer,
    this._envelope,
  );

  final Marmot _marmot;
  final LibraryFileStore _fileStore;
  final IdentityLocalDataSource _identity;
  final Ndk _ndk;
  final KeyPackageService _keyPackages;
  final DecodedMessageCache _cache;
  final GroupTransferService _transfer;
  final GroupEnvelopeService _envelope;
  final _log = logging.Logger('BookGroupDatasource');
  final Map<String, String> _groupIdByBookId = {};

  static const _groupDescription = 'ZapBook personal library book';
  static const _relays = NostrService.broadcastRelays;

  String _groupName(String bookId) => BookGroupNaming.nameFor(bookId);

  Future<List<LibraryBook>> loadLibrary() async {
    final groups = await _marmot.listGroups();
    final bookGroups = groups
        .where((group) => BookGroupNaming.matches(group.name))
        .toList();
    final reconstructed = await Future.wait(
      bookGroups.map((group) => _reconstruct(group.id)),
    );
    final books = <LibraryBook>[];
    for (var i = 0; i < bookGroups.length; i++) {
      final book = reconstructed[i];
      if (book == null) continue;
      _groupIdByBookId[book.id] = bookGroups[i].id;
      books.add(book.copyWith(memberCount: bookGroups[i].memberCount));
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
    _envelope.publish(metaEvent);

    if (coverBytes != null) {
      await _fileStore.writeCover(bookId, coverBytes);
      await _transfer.uploadGroupCover(groupId, coverBytes);
    }

    return _toLibraryBook(meta, lastReadAtMs: null);
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
    return _transfer.hydrateCover(bookId, group);
  }

  Future<void> sendMeta(String bookId, BookMetaPayload meta) async {
    final groupId = await _resolveGroupId(bookId);
    if (groupId == null) return;
    final npub = await _requireNpub();
    final event = await _marmot.sendStructured(npub, groupId, meta.toJson());
    _envelope.publish(event);
  }

  Future<void> sendProgress(
    String bookId,
    DateTime lastReadAt, {
    int? currentPage,
    int? currentWordCount,
    int? totalWordCount,
  }) async {
    final groupId = await _resolveGroupId(bookId);
    if (groupId == null) return;
    final npub = await _requireNpub();
    final payload = BookProgressPayload(
      bookId: bookId,
      lastReadAtMs: lastReadAt.millisecondsSinceEpoch,
      currentPage: currentPage,
      currentWordCount: currentWordCount,
      totalWordCount: totalWordCount,
    );
    try {
      final event = await _marmot.sendStructured(
        npub,
        groupId,
        payload.toJson(),
      );
      _envelope.publish(event);
    } on Object catch (error, stack) {
      _log.warning('Send progress failed for $bookId', error, stack);
    }
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

  Future<List<ShareSkip>> shareBook(String bookId, String memberNpub) =>
      shareBookWith(bookId, [memberNpub]);

  Future<List<ShareSkip>> shareBookWith(
    String bookId,
    List<String> memberNpubs,
  ) async {
    final groupId = await _resolveGroupId(bookId);
    if (groupId == null) {
      throw StateError('Book not found: $bookId');
    }

    final skipped = <ShareSkip>[];
    var added = 0;
    for (final memberNpub in memberNpubs) {
      final keyPackage = await _keyPackages.fetchKeyPackage(memberNpub);
      if (keyPackage == null) {
        _log.warning('No key package for $memberNpub — skipped');
        skipped.add(
          ShareSkip(npub: memberNpub, reason: ShareSkipReason.noKeyPackage),
        );
        continue;
      }
      final change = await _marmot.addMember(groupId, keyPackage);
      _envelope.publish(change.evolutionEventJson);

      final recipientHex = await MarmotIdentity.pubkeyHexFromNpub(memberNpub);
      for (final rumor in change.welcomeRumors) {
        await _envelope.giftWrapAndPublish(rumor, recipientHex);
      }
      added++;
    }

    if (added > 0) {
      final meta = await currentMeta(bookId);
      if (meta != null) await sendMeta(bookId, meta);
      await _transfer.uploadBookContent(await _requireNpub(), groupId, bookId);
    }

    return skipped;
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
    _envelope.publish(change.evolutionEventJson);
  }

  Future<void> leaveCircle(String bookId) async {
    final groupId = await _resolveGroupId(bookId);
    if (groupId != null) {
      try {
        final change = await _marmot.leaveGroup(groupId);
        _envelope.publish(change.evolutionEventJson);
      } on Object catch (error, stack) {
        _log.warning(
          'leaveGroup failed for $bookId, will still delete locally',
          error,
          stack,
        );
      }
      await _marmot.deleteGroup(groupId);
    }
    _groupIdByBookId.remove(bookId);
    await _fileStore.deleteBook(bookId);
  }

  Future<void> dissolveCircle(String bookId) async {
    final groupId = await _resolveGroupId(bookId);
    if (groupId == null) return;
    final myNpub = await _requireNpub();
    for (final member in await _marmot.getMembers(groupId)) {
      if (member.npub == myNpub) continue;
      final change = await _marmot.removeMember(groupId, member.npub);
      _envelope.publish(change.evolutionEventJson);
    }
  }

  Future<LibraryBook?> _reconstruct(String groupId) async {
    final messages = await _marmot.getMessages(groupId);
    final meta = _latestMeta(messages);
    if (meta == null) return null;
    final progress = _latestProgress(messages);
    return _toLibraryBook(
      meta,
      lastReadAtMs: progress?.lastReadAtMs,
      removedFromCircle: await _isRemoved(groupId),
    );
  }

  Future<bool> _isRemoved(String groupId) async {
    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return false;
    try {
      final members = await _marmot.getMembers(groupId);
      if (members.isEmpty) return false;
      return !members.any((member) => member.npub == npub);
    } on Object catch (error, stack) {
      _log.warning('Membership check failed for $groupId', error, stack);
      return false;
    }
  }

  BookMetaPayload? _latestMeta(List<MarmotMessage> messages) {
    BookMetaPayload? latest;
    var latestTs = -1;
    for (final message in messages) {
      final json = _cache.get(message);
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
      final json = _cache.get(message);
      if (json == null || json['type'] != BookMessageType.progress) continue;
      final payload = BookProgressPayload.fromJson(json);
      if (payload.lastReadAtMs >= latestMs) {
        latestMs = payload.lastReadAtMs;
        latest = payload;
      }
    }
    return latest;
  }

  Future<LibraryBook> _toLibraryBook(
    BookMetaPayload meta, {
    required int? lastReadAtMs,
    bool removedFromCircle = false,
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
      removedFromCircle: removedFromCircle,
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
      pageWords: manifest.pageWords,
      skippablePages: manifest.skippablePages,
    );
  }

  Future<bool> downloadBookContent(String bookId) async {
    final group = await _group(bookId);
    if (group == null) return false;
    await _ensureMessages(group.id, group.nostrGroupId);
    final messages = await _marmot.getMessages(group.id);
    final segmentRefs = _latestSegmentRefs(messages);
    if (segmentRefs.isEmpty) return false;
    final sourceRef = _latestMediaRef(messages, contains: '.source');
    return _transfer.downloadBookContent(
      bookId,
      group.id,
      segmentRefs,
      sourceRef,
    );
  }

  Future<SegmentData?> loadSegment(String bookId, int segmentIndex) async {
    final group = await _group(bookId);
    if (group == null) return null;
    await _ensureMessages(group.id, group.nostrGroupId);
    final messages = await _marmot.getMessages(group.id);
    final index = segmentIndex.toString().padLeft(4, '0');
    final ref = _latestMediaRef(messages, contains: '.seg$index.zbfseg');
    if (ref == null) return null;
    return _transfer.loadSegment(bookId, group.id, segmentIndex, ref);
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
          await _marmot.processIncoming(event.toMarmotJson());
        } on Object catch (_) {}
      }
      _caughtUp.add(groupId);
    } on Object catch (error, stack) {
      _log.warning('Catch-up fetch failed for $groupId', error, stack);
    }
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
}

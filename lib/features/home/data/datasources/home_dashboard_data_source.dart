import 'dart:async';
import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/domain/book_group_naming.dart';
import 'package:zapbook/core/data/library_file_store.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/decoded_message_cache.dart';
import 'package:zapbook/core/services/milestone_service.dart';
import 'package:zapbook/core/services/nostr_service.dart';
import 'package:zapbook/core/services/reading_stats_service.dart';
import 'package:zapbook/features/home/domain/entities/home_dashboard.dart';
import 'package:zapbook/features/library/domain/repositories/library_repository.dart';

abstract interface class HomeDashboardDataSource {
  Stream<HomeDashboard> watchDashboard();
  Future<void> touchBookOpened(String bookId);
}

final _log = logging.Logger('HomeDashboardDataSource');

@LazySingleton(as: HomeDashboardDataSource)
class HomeDashboardDataSourceImpl implements HomeDashboardDataSource {
  HomeDashboardDataSourceImpl(
    this._marmot,
    this._ndk,
    this._identityLocal,
    this._fileStore,
    this._stats,
    this._library,
    this._milestone,
    this._cache,
  );

  final Marmot _marmot;
  final Ndk _ndk;
  final IdentityLocalDataSource _identityLocal;
  final LibraryFileStore _fileStore;
  final ReadingStatsService _stats;
  final LibraryRepository _library;
  final MilestoneService _milestone;
  final DecodedMessageCache _cache;

  final _changeController = StreamController<void>.broadcast();

  @override
  Stream<HomeDashboard> watchDashboard() {
    final controller = StreamController<HomeDashboard>.broadcast();

    void reload() async {
      try {
        final data = await _fetchDashboard();
        if (!controller.isClosed) {
          controller.add(data);
        }
      } catch (error, stack) {
        _log.warning('dashboard reload failed', error, stack);
      }
    }

    reload();

    final libSub = _library.watchBooks().listen((_) => reload());
    final changeSub = _changeController.stream.listen((_) => reload());

    controller.onCancel = () {
      libSub.cancel();
      changeSub.cancel();
      controller.close();
    };

    return controller.stream;
  }

  @override
  Future<void> touchBookOpened(String bookId) async {
    final npub = await _identityLocal.readNpub();
    if (npub == null || npub.isEmpty) return;

    final name = BookGroupNaming.nameFor(bookId);
    final groups = await _marmot.listGroups();
    MarmotGroup? targetGroup;
    for (final group in groups) {
      if (group.name == name) {
        targetGroup = group;
        break;
      }
    }
    if (targetGroup == null) return;
    final groupId = targetGroup.id;

    final payload = {
      'type': 'zapbook.book.progress',
      'bookId': bookId,
      'lastReadAtMs': DateTime.now().millisecondsSinceEpoch,
    };
    await _marmot.sendStructured(npub, groupId, payload);

    _changeController.add(null);

    try {
      final messages = await _marmot.getMessages(groupId);
      var latestProgressMs = -1;
      Map<String, dynamic>? latestProgress;

      for (final msg in messages) {
        final decoded = _cache.get(msg);
        if (decoded == null) continue;
        if (decoded['type'] == 'zapbook.book.progress') {
          final lastReadAtMs = decoded['lastReadAtMs'] as num?;
          if (lastReadAtMs != null &&
              lastReadAtMs.toInt() >= latestProgressMs) {
            latestProgressMs = lastReadAtMs.toInt();
            latestProgress = decoded;
          }
        }
      }

      if (latestProgress != null) {
        final eventJson = jsonEncode({
          'id': latestProgress['id'],
          'pubkey': latestProgress['pubkey'] ?? npub,
          'created_at':
              latestProgress['created_at'] ??
              (DateTime.now().millisecondsSinceEpoch ~/ 1000),
          'kind': 445,
          'tags': [
            ['h', targetGroup.nostrGroupId],
          ],
          'content': jsonEncode(latestProgress),
          'sig': latestProgress['sig'],
        });

        final map = jsonDecode(eventJson) as Map<String, dynamic>;
        final tags = (map['tags'] as List)
            .map((tag) => (tag as List).map((e) => e.toString()).toList())
            .toList();
        String pubKey = map['pubkey'] as String;
        if (pubKey.startsWith('npub')) {
          pubKey = Nip19.decode(pubKey);
        }
        final nipEvent = Nip01Event(
          id: map['id'] as String?,
          pubKey: pubKey,
          kind: (map['kind'] as num).toInt(),
          tags: tags,
          content: map['content'] as String,
          sig: map['sig'] as String?,
          createdAt: (map['created_at'] as num).toInt(),
        );
        _ndk.broadcast.broadcast(
          nostrEvent: nipEvent,
          specificRelays: NostrService.broadcastRelays,
        );
      }
    } catch (error, stack) {
      _log.warning('progress broadcast failed', error, stack);
    }
  }

  Future<HomeDashboard> _fetchDashboard() async {
    final books = await _fetchBooks();
    final stats = await _fetchStats();
    return HomeDashboard(stats: stats, books: books);
  }

  Future<HomeDashboardStats> _fetchStats() async {
    await _stats.load();
    return HomeDashboardStats(
      dayStreak: _stats.streak,
      satsEarned: _stats.satsEarned,
      booksRead: _stats.booksRead,
    );
  }

  Future<List<HomeDashboardBook>> _fetchBooks() async {
    final myNpub = await _identityLocal.readNpub();
    final groups = await _marmot.listGroups();
    final bookGroups = groups
        .where((group) => BookGroupNaming.matches(group.name))
        .toList();
    final results = await Future.wait(
      bookGroups.map((group) => _bookFromGroup(group, myNpub)),
    );
    final books = results.whereType<HomeDashboardBook>().toList();

    books.sort((a, b) {
      if (a.lastOpenedAt != null && b.lastOpenedAt != null) {
        return b.lastOpenedAt!.compareTo(a.lastOpenedAt!);
      }
      if (a.lastOpenedAt != null) return -1;
      if (b.lastOpenedAt != null) return 1;
      return b.id.compareTo(a.id);
    });

    return books;
  }

  Future<HomeDashboardBook?> _bookFromGroup(
    MarmotGroup group,
    String? myNpub,
  ) async {
    final bookId = BookGroupNaming.bookIdOf(group.name);
    final messages = await _marmot.getMessages(group.id);

    Map<String, dynamic>? latestMeta;
    var latestMetaTs = -1;
    var latestProgressMs = -1;

    for (final msg in messages) {
      final decoded = _cache.get(msg);
      if (decoded == null) continue;
      final isMine = myNpub != null && msg.senderNpub == myNpub;
      final type = decoded['type'];
      if (type == 'zapbook.book.meta') {
        final ts = msg.timestampSecs.toInt();
        if (ts >= latestMetaTs) {
          latestMetaTs = ts;
          latestMeta = decoded;
        }
        continue;
      }
      _milestone.ingestMessage(msg);
      if (isMine && type == 'zapbook.book.progress') {
        final lastReadAtMs = decoded['lastReadAtMs'] as num?;
        if (lastReadAtMs != null &&
            lastReadAtMs.toInt() >= latestProgressMs) {
          latestProgressMs = lastReadAtMs.toInt();
        }
      }
    }

    if (latestMeta == null) return null;

    final metaBookId = latestMeta['bookId'] as String? ?? bookId;
    final title = latestMeta['title'] as String? ?? 'Untitled';
    final author = latestMeta['author'] as String? ?? '';
    final pageCount = (latestMeta['pageCount'] as num?)?.toInt() ?? 0;

    final zbf = await _fileStore.zbfFile(metaBookId);
    final coverPath = await _fileStore.coverPathIfExists(metaBookId);
    final mine = myNpub != null
        ? _milestone.membersOf(metaBookId)[myNpub]
        : null;

    return HomeDashboardBook(
      id: metaBookId,
      title: title,
      author: author,
      coverPath: coverPath,
      pageCount: pageCount,
      memberCount: group.memberCount,
      zbfPath: zbf.path,
      lastOpenedAt: latestProgressMs == -1
          ? null
          : DateTime.fromMillisecondsSinceEpoch(latestProgressMs),
      currentPage: mine?.currentPage ?? 0,
      totalWords: mine?.totalWordCount ?? 0,
      currentWordCount: mine?.currentWordCount ?? 0,
      fraction: mine?.fraction ?? 0,
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/data/library_file_store.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/nostr_service.dart';
import 'package:zapbook/core/services/reading_stats_service.dart';
import 'package:zapbook/features/home/domain/entities/home_dashboard.dart';
import 'package:zapbook/features/library/domain/repositories/library_repository.dart';

abstract interface class HomeDashboardDataSource {
  Stream<HomeDashboard> watchDashboard();
  Future<void> touchBookOpened(String bookId);
}

@LazySingleton(as: HomeDashboardDataSource)
class HomeDashboardDataSourceImpl implements HomeDashboardDataSource {
  HomeDashboardDataSourceImpl(
    this._marmot,
    this._ndk,
    this._identityLocal,
    this._fileStore,
    this._stats,
    this._library,
  );

  final Marmot _marmot;
  final Ndk _ndk;
  final IdentityLocalDataSource _identityLocal;
  final LibraryFileStore _fileStore;
  final ReadingStatsService _stats;
  final LibraryRepository _library;

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
      } catch (_) {}
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

    final name = 'zapbook-book-$bookId';
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
    await _marmot.sendStructured(
      npub,
      groupId,
      payload,
    );

    _changeController.add(null);

    try {
      final messages = await _marmot.getMessages(groupId);
      var latestProgressMs = -1;
      Map<String, dynamic>? latestProgress;

      for (final msg in messages) {
        final raw = msg.payloadJson;
        if (raw == null || raw.isEmpty) continue;
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic> &&
              decoded['type'] == 'zapbook.book.progress') {
            final lastReadAtMs = decoded['lastReadAtMs'] as num?;
            if (lastReadAtMs != null &&
                lastReadAtMs.toInt() >= latestProgressMs) {
              latestProgressMs = lastReadAtMs.toInt();
              latestProgress = decoded;
            }
          }
        } catch (_) {}
      }

      if (latestProgress != null) {
        final eventJson = jsonEncode({
          'id': latestProgress['id'],
          'pubkey': latestProgress['pubkey'] ?? npub,
          'created_at': latestProgress['created_at'] ??
              (DateTime.now().millisecondsSinceEpoch ~/ 1000),
          'kind': 445,
          'tags': [
            ['h', targetGroup.nostrGroupId]
          ],
          'content': jsonEncode(latestProgress),
          'sig': latestProgress['sig'],
        });

        final map = jsonDecode(eventJson) as Map<String, dynamic>;
        final tags = (map['tags'] as List)
            .map((tag) => (tag as List).map((e) => e.toString()).toList())
            .toList();
        final nipEvent = Nip01Event(
          id: map['id'] as String?,
          pubKey: map['pubkey'] as String,
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
    } catch (_) {}
  }

  Future<HomeDashboard> _fetchDashboard() async {
    final stats = await _fetchStats();
    final books = await _fetchBooks();
    return HomeDashboard(stats: stats, books: books);
  }

  Future<HomeDashboardStats> _fetchStats() async {
    return HomeDashboardStats(
      dayStreak: _stats.streak,
      satsEarned: _stats.satsEarned,
      booksRead: _stats.booksRead,
    );
  }

  Future<List<HomeDashboardBook>> _fetchBooks() async {
    final myNpub = await _identityLocal.readNpub();
    final groups = await _marmot.listGroups();
    final books = <HomeDashboardBook>[];
    for (final group in groups) {
      if (!group.name.startsWith('zapbook-book-')) continue;

      final bookId = group.name.replaceFirst('zapbook-book-', '');
      final messages = await _marmot.getMessages(group.id);

      Map<String, dynamic>? latestMeta;
      var latestMetaTs = -1;
      var latestProgressMs = -1;
      var latestPage = 0;
      var latestTotalWords = 0;
      var latestWordCount = 0;

      for (final msg in messages) {
        final raw = msg.payloadJson;
        if (raw == null || raw.isEmpty) continue;
        final isMine = myNpub != null && msg.senderNpub == myNpub;
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            final type = decoded['type'];
            if (type == 'zapbook.book.meta') {
              final ts = msg.timestampSecs.toInt();
              if (ts >= latestMetaTs) {
                latestMetaTs = ts;
                latestMeta = decoded;
              }
            } else if (type == 'zapbook.book.progress') {
              if (!isMine) continue;
              final lastReadAtMs = decoded['lastReadAtMs'] as num?;
              if (lastReadAtMs != null &&
                  lastReadAtMs.toInt() >= latestProgressMs) {
                latestProgressMs = lastReadAtMs.toInt();
              }
              final cp = (decoded['currentPage'] as num?)?.toInt() ?? 0;
              if (cp > latestPage) {
                latestPage = cp;
                latestWordCount =
                    (decoded['currentWordCount'] as num?)?.toInt() ?? 0;
                latestTotalWords =
                    (decoded['totalWordCount'] as num?)?.toInt() ?? 0;
              }
            } else if (type == 'zapbook.book.milestone') {
              if (!isMine) continue;
              final cp = (decoded['current_page'] as num?)?.toInt() ?? 0;
              if (cp >= latestPage) {
                latestPage = cp;
                latestTotalWords =
                    (decoded['total_word_count'] as num?)?.toInt() ?? 0;
                latestWordCount =
                    (decoded['current_word_count'] as num?)?.toInt() ?? 0;
              }
            }
          }
        } catch (_) {}
      }

      if (latestMeta == null) continue;

      final metaBookId = latestMeta['bookId'] as String? ?? bookId;
      final title = latestMeta['title'] as String? ?? 'Untitled';
      final author = latestMeta['author'] as String? ?? '';
      final pageCount = (latestMeta['pageCount'] as num?)?.toInt() ?? 0;

      final zbf = await _fileStore.zbfFile(metaBookId);
      final coverPath = await _fileStore.coverPathIfExists(metaBookId);

      books.add(
        HomeDashboardBook(
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
          currentPage: latestPage,
          totalWords: latestTotalWords,
          currentWordCount: latestWordCount,
        ),
      );
    }

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
}

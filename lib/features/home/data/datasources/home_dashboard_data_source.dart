import 'dart:async';
import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/data/library_file_store.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/nostr_service.dart';
import 'package:zapbook/features/home/domain/entities/home_dashboard.dart';

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
  );

  final Marmot _marmot;
  final Ndk _ndk;
  final IdentityLocalDataSource _identityLocal;
  final LibraryFileStore _fileStore;

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

    final timer = Timer.periodic(const Duration(seconds: 5), (_) => reload());
    final sub = _changeController.stream.listen((_) => reload());

    controller.onCancel = () {
      timer.cancel();
      sub.cancel();
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
    return const HomeDashboardStats(
      dayStreak: 0,
      satsEarned: 0,
      booksRead: 0,
    );
  }

  Future<List<HomeDashboardBook>> _fetchBooks() async {
    final groups = await _marmot.listGroups();
    final books = <HomeDashboardBook>[];
    for (final group in groups) {
      if (!group.name.startsWith('zapbook-book-')) continue;

      final bookId = group.name.replaceFirst('zapbook-book-', '');
      final messages = await _marmot.getMessages(group.id);

      Map<String, dynamic>? latestMeta;
      var latestMetaTs = -1;
      var latestProgressMs = -1;

      for (final msg in messages) {
        final raw = msg.payloadJson;
        if (raw == null || raw.isEmpty) continue;
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
              final lastReadAtMs = decoded['lastReadAtMs'] as num?;
              if (lastReadAtMs != null &&
                  lastReadAtMs.toInt() >= latestProgressMs) {
                latestProgressMs = lastReadAtMs.toInt();
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

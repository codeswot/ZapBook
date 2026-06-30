import 'dart:async';
import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/config/zapbook_config.dart';
import 'package:zapbook/core/domain/book_group_naming.dart';

import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/circle_store_service.dart';
import 'package:zapbook/core/services/reading_stats_service.dart';
import 'package:zapbook/features/home/domain/entities/home_dashboard.dart';

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
    this._stats,
    this._circleStore,
  );

  final Marmot _marmot;
  final Ndk _ndk;
  final IdentityLocalDataSource _identityLocal;

  final ReadingStatsService _stats;
  final CircleStoreService _circleStore;

  final _changeController = StreamController<void>.broadcast();

  @override
  Stream<HomeDashboard> watchDashboard() {
    return Rx.combineLatest3(
      _circleStore.watchCircleBooks,
      _circleStore.watchLastOpenedCircleBook,
      _changeController.stream.startWith(null),
      (circles, lastOpened, _) async {
        final stats = await _fetchStats();
        return HomeDashboard(
          stats: stats,
          circles: circles.toList(),
          lastOpenedCircleBook: lastOpened,
        );
      },
    ).asyncMap((event) => event);
  }

  @override
  Future<void> touchBookOpened(String bookId) async {
    final npub = await _identityLocal.readNpub();
    if (npub == null || npub.isEmpty) return;

    final name = BookGroupNaming.legacyNameFor(bookId);
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
    final eventJsonStr = await _marmot.sendStructured(npub, groupId, payload);

    _changeController.add(null);

    try {
      final map = jsonDecode(eventJsonStr) as Map<String, dynamic>;
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
        specificRelays: ZapbookConfig.broadcastRelays,
      );
    } catch (error, stack) {
      _log.warning('mark read broadcast failed', error, stack);
    }
  }

  Future<HomeDashboardStats> _fetchStats() async {
    await _stats.load();
    return HomeDashboardStats(
      dayStreak: _stats.streak,
      satsEarned: _stats.satsEarned,
      booksRead: _stats.booksRead,
    );
  }
}

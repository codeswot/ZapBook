import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:zapbook/core/data/database/dao/zap_sats_earnings_dao.dart';

import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/data/infrastructure/circle_store_service.dart';
import 'package:zapbook/core/data/infrastructure/reading_stats_service.dart';
import 'package:zapbook/features/home/domain/entities/home_dashboard.dart';

import 'package:zapbook/core/data/database/dao/circle_progress_dao.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class HomeDashboardDataSource {
  Stream<HomeDashboard> watchDashboard();
  Future<void> touchBookOpened(String circleBookId);
}

@LazySingleton(as: HomeDashboardDataSource)
class HomeDashboardDataSourceImpl implements HomeDashboardDataSource {
  HomeDashboardDataSourceImpl(
    this._identityLocal,
    this._stats,
    this._circleStore,
    this._progressDao,
    this._earningsDao,
    this._prefs,
  );

  final IdentityLocalDataSource _identityLocal;

  final ReadingStatsService _stats;
  final CircleStoreService _circleStore;
  final CircleProgressDao _progressDao;
  final ZapSatsEarningsDao _earningsDao;
  final SharedPreferences _prefs;

  final _changeController = StreamController<void>.broadcast();

  @override
  Stream<HomeDashboard> watchDashboard() {
    return Stream.fromFuture(_identityLocal.readNpub()).asyncExpand((myNpub) {
      final owner = myNpub ?? '';
      return Rx.combineLatest4(
        _circleStore.watchCircleBooks,
        _stats.watchStats(),
        _earningsDao.watchTotalSats(owner),
        _changeController.stream.startWith(null),
        (circles, statsRecord, satsEarned, _) async {
          final stats = HomeDashboardStats(
            dayStreak: statsRecord?.effectiveStreak ?? 0,
            satsEarned: satsEarned,
            booksRead: statsRecord?.booksRead ?? 0,
          );

          CircleBook? lastOpened;

          if (owner.isNotEmpty) {
            final lastOpenedDirId = _prefs.getString('last_opened_$owner');
            if (lastOpenedDirId != null) {
              for (final c in circles) {
                if (c.circleDirId == lastOpenedDirId) {
                  lastOpened = c;
                  break;
                }
              }
            }
          }

          return (circles, lastOpened, owner, stats);
        },
      ).asyncMap((event) => event).switchMap((data) {
        final circles = data.$1;
        final lastOpened = data.$2;
        final npub = data.$3;
        final stats = data.$4;

        if (lastOpened == null || npub.isEmpty) {
          return Stream.value(
            HomeDashboard(
              stats: stats,
              circles: circles.toList(),
              lastOpenedCircleBook: lastOpened,
            ),
          );
        }

        return _progressDao
            .watchMyProgress(
              groupId: lastOpened.id,
              bookId: lastOpened.circleDirId,
              myNpub: npub,
            )
            .map((progress) {
              return HomeDashboard(
                stats: stats,
                circles: circles.toList(),
                lastOpenedCircleBook: lastOpened,
                lastOpenedProgress: progress?.progressPercentage,
                lastOpenedPage: progress?.pageIndex,
              );
            });
      });
    });
  }

  @override
  Future<void> touchBookOpened(String circleBookId) async {
    final npub = await _identityLocal.readNpub();
    if (npub == null || npub.isEmpty) return;

    await _prefs.setString('last_opened_$npub', circleBookId);
    _changeController.add(null);
  }
}

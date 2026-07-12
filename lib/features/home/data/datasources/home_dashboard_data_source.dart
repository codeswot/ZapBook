import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/circle_store_service.dart';
import 'package:zapbook/core/services/reading_stats_service.dart';
import 'package:zapbook/features/home/domain/entities/home_dashboard.dart';

import 'package:zapbook/core/data/dao/circle_progress_dao.dart';
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
    this._prefs,
  );

  final IdentityLocalDataSource _identityLocal;

  final ReadingStatsService _stats;
  final CircleStoreService _circleStore;
  final CircleProgressDao _progressDao;
  final SharedPreferences _prefs;

  final _changeController = StreamController<void>.broadcast();

  @override
  Stream<HomeDashboard> watchDashboard() {
    return Rx.combineLatest3(
      _circleStore.watchCircleBooks,
      _stats.watchStats(),
      _changeController.stream.startWith(null),
      (circles, statsRecord, _) async {
        final stats = HomeDashboardStats(
          dayStreak: statsRecord?.effectiveStreak ?? 0,
          satsEarned: statsRecord?.satsEarned ?? 0,
          booksRead: statsRecord?.booksRead ?? 0,
        );

        final npub = await _identityLocal.readNpub();

        CircleBook? lastOpened;

        if (npub != null && npub.isNotEmpty) {
          final lastOpenedDirId = _prefs.getString('last_opened_$npub');
          if (lastOpenedDirId != null) {
            for (final c in circles) {
              if (c.circleDirId == lastOpenedDirId) {
                lastOpened = c;
                break;
              }
            }
          }
        }

        return (circles, lastOpened, npub, stats);
      },
    ).asyncMap((event) => event).switchMap((data) {
      final circles = data.$1;
      final lastOpened = data.$2;
      final npub = data.$3;
      final stats = data.$4;

      if (lastOpened == null || npub == null) {
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
  }

  @override
  Future<void> touchBookOpened(String circleBookId) async {
    final npub = await _identityLocal.readNpub();
    if (npub == null || npub.isEmpty) return;

    await _prefs.setString('last_opened_$npub', circleBookId);
    _changeController.add(null);
  }
}

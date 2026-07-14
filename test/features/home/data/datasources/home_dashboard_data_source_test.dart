import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zapbook/core/data/database/dao/circle_progress_dao.dart';
import 'package:zapbook/core/data/database/dao/zap_sats_earnings_dao.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/circle_store_service.dart';
import 'package:zapbook/core/services/reading_stats_service.dart';
import 'package:zapbook/features/home/data/datasources/home_dashboard_data_source.dart';

class MockIdentityLocalDataSource extends Mock
    implements IdentityLocalDataSource {}

class MockReadingStatsService extends Mock implements ReadingStatsService {}

class MockCircleStoreService extends Mock implements CircleStoreService {}

class MockCircleProgressDao extends Mock implements CircleProgressDao {}

class MockZapSatsEarningsDao extends Mock implements ZapSatsEarningsDao {}

void main() {
  late MockIdentityLocalDataSource identityLocal;
  late MockReadingStatsService stats;
  late MockCircleStoreService circleStore;
  late MockCircleProgressDao progressDao;
  late MockZapSatsEarningsDao earningsDao;
  late SharedPreferences prefs;

  late HomeDashboardDataSourceImpl dataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    identityLocal = MockIdentityLocalDataSource();
    stats = MockReadingStatsService();
    circleStore = MockCircleStoreService();
    progressDao = MockCircleProgressDao();
    earningsDao = MockZapSatsEarningsDao();

    dataSource = HomeDashboardDataSourceImpl(
      identityLocal,
      stats,
      circleStore,
      progressDao,
      earningsDao,
      prefs,
    );
  });

  test('watchDashboard emits data correctly', () async {
    when(
      () => circleStore.watchCircleBooks,
    ).thenAnswer((_) => Stream.value([]));
    when(() => stats.watchStats()).thenAnswer((_) => Stream.value(null));
    when(
      () => earningsDao.watchTotalSats(),
    ).thenAnswer((_) => Stream.value(100));
    when(() => identityLocal.readNpub()).thenAnswer((_) async => 'npub123');

    final dashboard = await dataSource.watchDashboard().first;

    expect(dashboard.stats.satsEarned, 100);
    expect(dashboard.stats.dayStreak, 0);
    expect(dashboard.stats.booksRead, 0);
    expect(dashboard.circles, isEmpty);
    expect(dashboard.lastOpenedCircleBook, isNull);
  });

  test('touchBookOpened updates prefs', () async {
    when(() => identityLocal.readNpub()).thenAnswer((_) async => 'npub123');
    await dataSource.touchBookOpened('bookId123');
    expect(prefs.getString('last_opened_npub123'), 'bookId123');
  });
}

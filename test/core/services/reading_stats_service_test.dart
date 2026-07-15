import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ndk/ndk.dart';

import 'package:zapbook/core/data/infrastructure/reading_stats_service.dart';
import 'package:zapbook/core/data/database/dao/circle_progress_dao.dart';
import 'package:zapbook/core/data/database/dao/reading_stats_dao.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/data/infrastructure/zap_earnings_service.dart';

import 'package:zapbook/core/data/database/dao/zap_sats_earnings_dao.dart';

class MockCircleProgressDao extends Mock implements CircleProgressDao {}

class MockReadingStatsDao extends Mock implements ReadingStatsDao {}

class MockZapSatsEarningsDao extends Mock implements ZapSatsEarningsDao {}

class MockIdentityLocalDataSource extends Mock
    implements IdentityLocalDataSource {}

class MockZapEarningsService extends Mock implements ZapEarningsService {}

class MockNdk extends Mock implements Ndk {}

class MockRequests extends Mock implements Requests {}

class MockBroadcast extends Mock implements Broadcast {}

class MockAccounts extends Mock implements Accounts {}

class MockAccount extends Mock implements Account {}

class MockSigner extends Mock implements EventSigner {}

class FakeReadingStatsRecord extends Fake implements ReadingStatsRecord {}

class FakeFilter extends Fake implements Filter {}

class FakeNip01Event extends Fake implements Nip01Event {}

void main() {
  late MockCircleProgressDao mockProgressDao;
  late MockReadingStatsDao mockStatsDao;
  late MockZapSatsEarningsDao mockEarningsDao;
  late MockIdentityLocalDataSource mockIdentity;
  late MockZapEarningsService mockEarnings;
  late MockNdk mockNdk;
  late MockRequests mockRequests;
  late MockBroadcast mockBroadcast;
  late MockAccounts mockAccounts;
  late MockAccount mockAccount;
  late MockSigner mockSigner;

  late ReadingStatsService service;

  setUpAll(() {
    registerFallbackValue(FakeReadingStatsRecord());
    registerFallbackValue(FakeFilter());
    registerFallbackValue(FakeNip01Event());
  });

  setUp(() {
    mockProgressDao = MockCircleProgressDao();
    mockStatsDao = MockReadingStatsDao();
    mockEarningsDao = MockZapSatsEarningsDao();
    mockIdentity = MockIdentityLocalDataSource();
    mockEarnings = MockZapEarningsService();
    mockNdk = MockNdk();
    mockRequests = MockRequests();
    mockBroadcast = MockBroadcast();
    mockAccounts = MockAccounts();
    mockAccount = MockAccount();
    mockSigner = MockSigner();

    when(() => mockNdk.requests).thenReturn(mockRequests);
    when(() => mockNdk.broadcast).thenReturn(mockBroadcast);
    when(() => mockNdk.accounts).thenReturn(mockAccounts);

    when(
      () => mockIdentity.readNpub(),
    ).thenAnswer((_) => Future.value('pubkey1'));
    when(
      () => mockEarningsDao.getTotalSats(any()),
    ).thenAnswer((_) => Future.value(100));
    when(() => mockEarnings.start()).thenAnswer((_) => Future.value());
    when(
      () => mockProgressDao.countCompletedBooks(any()),
    ).thenAnswer((_) => Future.value(5));
    when(
      () => mockProgressDao.sumMilestonesReached(any()),
    ).thenAnswer((_) => Future.value(10));

    service = ReadingStatsService(
      mockProgressDao,
      mockStatsDao,
      mockEarningsDao,
      mockIdentity,
      mockEarnings,
      mockNdk,
    );
  });

  String today() => DateTime.now().toUtc().toIso8601String().substring(0, 10);
  String yesterday() => DateTime.now()
      .toUtc()
      .subtract(const Duration(days: 1))
      .toIso8601String()
      .substring(0, 10);
  String dayBeforeYesterday() => DateTime.now()
      .toUtc()
      .subtract(const Duration(days: 2))
      .toIso8601String()
      .substring(0, 10);

  test('getStats fetches from stats dao for local user', () async {
    final record = ReadingStatsRecord(
      pubKey: 'pubkey1',
      streak: 3,
      lastActivityDate: today(),
      booksRead: 5,
      updatedAt: 123456789,
    );
    when(
      () => mockStatsDao.getStats('pubkey1'),
    ).thenAnswer((_) async => record);
    final stats = await service.getStats(null);
    expect(stats, record);
    verify(() => mockStatsDao.getStats('pubkey1')).called(1);
  });

  test('getMilestones fetches from progress dao', () async {
    final milestones = await service.getMilestones();
    expect(milestones, 10);
    verify(() => mockProgressDao.sumMilestonesReached('pubkey1')).called(1);
  });

  test(
    'recordProgressMade increments streak if last activity was yesterday',
    () async {
      when(() => mockStatsDao.getStats('pubkey1')).thenAnswer(
        (_) async => ReadingStatsRecord(
          pubKey: 'pubkey1',
          streak: 3,
          lastActivityDate: yesterday(),
          booksRead: 5,
          updatedAt: 123456789,
        ),
      );
      when(() => mockStatsDao.upsertStats(any())).thenAnswer((_) async {});
      when(() => mockAccounts.getLoggedAccount()).thenReturn(mockAccount);
      when(() => mockAccount.signer).thenReturn(mockSigner);
      when(() => mockAccount.pubkey).thenReturn('pubkey1');
      when(() => mockSigner.canSign()).thenReturn(true);
      when(() => mockSigner.sign(any())).thenAnswer(
        (_) async => Nip01Event(pubKey: '', kind: 1, tags: [], content: ''),
      );

      await service.recordProgressMade();

      final recordCapture = verify(
        () => mockStatsDao.upsertStats(captureAny()),
      ).captured;
      final ReadingStatsRecord record =
          recordCapture.first as ReadingStatsRecord;

      expect(record.streak, 4);
      expect(record.lastActivityDate, today());
      expect(record.booksRead, 5);

      verify(
        () => mockBroadcast.broadcast(
          nostrEvent: any(named: 'nostrEvent'),
          specificRelays: any(named: 'specificRelays'),
        ),
      ).called(1);
    },
  );

  test(
    'recordProgressMade resets streak if last activity was before yesterday',
    () async {
      when(() => mockStatsDao.getStats('pubkey1')).thenAnswer(
        (_) async => ReadingStatsRecord(
          pubKey: 'pubkey1',
          streak: 3,
          lastActivityDate: dayBeforeYesterday(),
          booksRead: 5,
          updatedAt: 123456789,
        ),
      );
      when(() => mockStatsDao.upsertStats(any())).thenAnswer((_) async {});
      when(() => mockAccounts.getLoggedAccount()).thenReturn(mockAccount);
      when(() => mockAccount.signer).thenReturn(mockSigner);
      when(() => mockAccount.pubkey).thenReturn('pubkey1');
      when(() => mockSigner.canSign()).thenReturn(true);
      when(() => mockSigner.sign(any())).thenAnswer(
        (_) async => Nip01Event(pubKey: '', kind: 1, tags: [], content: ''),
      );

      await service.recordProgressMade();

      final recordCapture = verify(
        () => mockStatsDao.upsertStats(captureAny()),
      ).captured;
      final ReadingStatsRecord record =
          recordCapture.first as ReadingStatsRecord;

      expect(record.streak, 1);
      expect(record.lastActivityDate, today());

      verify(
        () => mockBroadcast.broadcast(
          nostrEvent: any(named: 'nostrEvent'),
          specificRelays: any(named: 'specificRelays'),
        ),
      ).called(1);
    },
  );

  test('recordProgressMade does nothing if already recorded today', () async {
    when(() => mockStatsDao.getStats('pubkey1')).thenAnswer(
      (_) async => ReadingStatsRecord(
        pubKey: 'pubkey1',
        streak: 3,
        lastActivityDate: today(),
        booksRead: 5,
        updatedAt: 123456789,
      ),
    );

    await service.recordProgressMade();

    verifyNever(() => mockStatsDao.upsertStats(any()));
    verifyNever(
      () => mockBroadcast.broadcast(
        nostrEvent: any(named: 'nostrEvent'),
        specificRelays: any(named: 'specificRelays'),
      ),
    );
  });

  test('watchStats yields current stats', () async {
    final record = ReadingStatsRecord(
      pubKey: 'pubkey1',
      streak: 5,
      booksRead: 0,
      updatedAt: 0,
    );
    final controller = StreamController<ReadingStatsRecord?>();
    when(
      () => mockStatsDao.watchStats('pubkey1'),
    ).thenAnswer((_) => controller.stream);

    final stream = service.watchStats();

    expect(stream, emitsInOrder([null, record, null]));

    controller.add(null);
    controller.add(record);
    controller.add(null);

    await Future.delayed(Duration.zero);
    await controller.close();
  });
}

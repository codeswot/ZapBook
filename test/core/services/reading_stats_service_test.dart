import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:marmot_dart/marmot_dart.dart';

import 'package:zapbook/core/services/reading_stats_service.dart';
import 'package:zapbook/core/data/dao/circle_progress_dao.dart';
import 'package:zapbook/core/data/dao/reading_stats_dao.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/zap_earnings_service.dart';
import 'package:zapbook/core/services/group_envelope_service.dart';

class MockCircleProgressDao extends Mock implements CircleProgressDao {}

class MockReadingStatsDao extends Mock implements ReadingStatsDao {}

class MockIdentityLocalDataSource extends Mock
    implements IdentityLocalDataSource {}

class MockZapEarningsService extends Mock implements ZapEarningsService {}

class MockMarmot extends Mock implements Marmot {}

class MockGroupEnvelopeService extends Mock implements GroupEnvelopeService {}

class FakeReadingStatsRecord extends Fake implements ReadingStatsRecord {}

void main() {
  late MockCircleProgressDao mockProgressDao;
  late MockReadingStatsDao mockStatsDao;
  late MockIdentityLocalDataSource mockIdentity;
  late MockZapEarningsService mockEarnings;
  late MockMarmot mockMarmot;
  late MockGroupEnvelopeService mockEnvelope;

  late ReadingStatsService service;

  setUpAll(() {
    registerFallbackValue(FakeReadingStatsRecord());
  });

  setUp(() {
    mockProgressDao = MockCircleProgressDao();
    mockStatsDao = MockReadingStatsDao();
    mockIdentity = MockIdentityLocalDataSource();
    mockEarnings = MockZapEarningsService();
    mockMarmot = MockMarmot();
    mockEnvelope = MockGroupEnvelopeService();

    when(
      () => mockIdentity.readNpub(),
    ).thenAnswer((_) => Future.value('pubkey1'));
    when(() => mockEarnings.totalEarned).thenReturn(ValueNotifier<int>(100));
    when(() => mockEarnings.earnedForCircle(any())).thenReturn(50);
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
      mockIdentity,
      mockEarnings,
      mockMarmot,
      mockEnvelope,
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

  test('getStats fetches from stats dao', () async {
    final record = ReadingStatsRecord(
      pubKey: 'pubkey1',
      streak: 3,
      lastActivityDate: today(),
      booksRead: 5,
      satsEarned: 100,
      updatedAt: 123456789,
    );
    when(
      () => mockStatsDao.getStats('pubkey1'),
    ).thenAnswer((_) async => record);
    final stats = await service.getStats();
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
          satsEarned: 100,
          updatedAt: 123456789,
        ),
      );
      when(() => mockStatsDao.upsertStats(any())).thenAnswer((_) async {});
      when(() => mockMarmot.sendStructured(any(), any(), any())).thenAnswer(
        (_) async =>
            '{"pubkey": "a", "kind": 1, "tags": [], "content": "", "created_at": 0}',
      );
      when(() => mockEnvelope.publish(any())).thenAnswer((_) async {});

      await service.recordProgressMade('group1');

      final recordCapture = verify(
        () => mockStatsDao.upsertStats(captureAny()),
      ).captured;
      final ReadingStatsRecord record =
          recordCapture.first as ReadingStatsRecord;

      expect(record.streak, 4);
      expect(record.lastActivityDate, today());
      expect(record.booksRead, 5);
      expect(record.satsEarned, 100);

      verify(
        () => mockMarmot.sendStructured('pubkey1', 'group1', any()),
      ).called(1);
      verify(() => mockEnvelope.publish(any())).called(1);
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
          satsEarned: 100,
          updatedAt: 123456789,
        ),
      );
      when(() => mockStatsDao.upsertStats(any())).thenAnswer((_) async {});
      when(() => mockMarmot.sendStructured(any(), any(), any())).thenAnswer(
        (_) async =>
            '{"pubkey": "a", "kind": 1, "tags": [], "content": "", "created_at": 0}',
      );
      when(() => mockEnvelope.publish(any())).thenAnswer((_) async {});

      await service.recordProgressMade('group1');

      final recordCapture = verify(
        () => mockStatsDao.upsertStats(captureAny()),
      ).captured;
      final ReadingStatsRecord record =
          recordCapture.first as ReadingStatsRecord;

      expect(record.streak, 1);
      expect(record.lastActivityDate, today());

      verify(
        () => mockMarmot.sendStructured('pubkey1', 'group1', any()),
      ).called(1);
      verify(() => mockEnvelope.publish(any())).called(1);
    },
  );

  test('recordProgressMade does nothing if already recorded today', () async {
    when(() => mockStatsDao.getStats('pubkey1')).thenAnswer(
      (_) async => ReadingStatsRecord(
        pubKey: 'pubkey1',
        streak: 3,
        lastActivityDate: today(),
        booksRead: 5,
        satsEarned: 100,
        updatedAt: 123456789,
      ),
    );

    await service.recordProgressMade('group1');

    verifyNever(() => mockStatsDao.upsertStats(any()));
    verifyNever(() => mockMarmot.sendStructured(any(), any(), any()));
    verifyNever(() => mockEnvelope.publish(any()));
  });

  test('watchStats yields current stats', () async {
    final record = ReadingStatsRecord(
      pubKey: 'pubkey1',
      streak: 5,
      booksRead: 0,
      satsEarned: 0,
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

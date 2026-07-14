import 'package:zapbook/core/domain/entities/cheers_activity_type.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/domain/entities/cheers_activity_message.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/circle_store_service.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/core/data/dao/cheers_dao.dart';
import 'package:zapbook/features/cheers/data/datasources/cheers_data_source.dart';

import 'package:zapbook/zbf/enums/book_source_format.dart';

class MockCircleStoreService extends Mock implements CircleStoreService {}

class MockIdentityLocalDataSource extends Mock
    implements IdentityLocalDataSource {}

class MockCheersDao extends Mock implements CheersDao {}

class MockContactService extends Mock implements ContactService {}

void main() {
  group('CheersDataSourceImpl', () {
    late MockCircleStoreService circleStore;
    late MockIdentityLocalDataSource identityLocal;
    late MockCheersDao cheersDao;
    late MockContactService contactService;
    late CheersDataSourceImpl dataSource;

    setUp(() {
      circleStore = MockCircleStoreService();
      identityLocal = MockIdentityLocalDataSource();
      cheersDao = MockCheersDao();
      contactService = MockContactService();

      dataSource = CheersDataSourceImpl(
        circleStore,
        identityLocal,
        cheersDao,
        contactService,
      );
    });

    test('watchActivities returns empty list when no activities', () async {
      when(
        () => cheersDao.watchActivities(),
      ).thenAnswer((_) => Stream.value([]));

      final activities = await dataSource.watchActivities().first;
      expect(activities, isEmpty);
    });

    test('watchActivities maps messages to activities', () async {
      final now = DateTime.now();
      final msg = CheersActivityMessage(
        id: '1',
        groupId: 'g1',
        actorNpub: 'npub1${'a' * 58}',
        activityDescription: 'Cheered',
        timestamp: now,
        type: CheersActivityType.cheer,
        zapRecipientNpub: 'npub1${'b' * 58}',
        isUnread: false,
      );

      final circle = CircleBook(
        id: 'g1',
        circleDirId: 'g1',
        nostrGroudId: 'g1',
        title: 'Test Circle',
        author: 'Author',
        sourceFormat: BookSourceFormat.epub,
        pageCount: 1,
        chapterCount: 1,
        zbfPath: '',
        zbfVersion: '1.0',
        createdAt: DateTime.now(),
        addedAt: DateTime.now(),
        adminNpubs: const [],
        memberCount: 1,
        needsAiProcessing: false,
      );

      when(
        () => cheersDao.watchActivities(),
      ).thenAnswer((_) => Stream.value([msg]));
      when(() => identityLocal.readNpub()).thenAnswer((_) async => 'npub1my');
      when(() => circleStore.currentCircles).thenReturn([circle]);
      when(() => contactService.resolve('npub1${'a' * 58}')).thenAnswer(
        (_) async => Contact(npub: 'npub1${'a' * 58}', displayName: 'Alice'),
      );
      when(() => contactService.resolve('npub1${'b' * 58}')).thenAnswer(
        (_) async => Contact(npub: 'npub1${'b' * 58}', displayName: 'Bob'),
      );

      final activities = await dataSource.watchActivities().first;
      expect(activities, hasLength(1));

      final activity = activities.first;
      expect(activity.id, '1');
      expect(activity.bookCircleTitle, 'Test Circle');
      expect(activity.actorName, 'Alice');
      expect(activity.otherPartyName, 'Bob');
      expect(activity.targetDescription, 'Cheered');
      expect(activity.isMine, false);
    });

    test('watchActivities handles missing contacts and my npub', () async {
      final now = DateTime.now();
      final msg = CheersActivityMessage(
        id: '1',
        groupId: 'g1',
        actorNpub: 'npub1my',
        activityDescription: 'Cheered',
        timestamp: now,
        type: CheersActivityType.cheer,
        isUnread: false,
      );

      when(
        () => cheersDao.watchActivities(),
      ).thenAnswer((_) => Stream.value([msg]));
      when(() => identityLocal.readNpub()).thenAnswer((_) async => 'npub1my');
      when(() => circleStore.currentCircles).thenReturn([]);
      when(
        () => contactService.resolve('npub1my'),
      ).thenThrow(Exception('No contact'));

      final activities = await dataSource.watchActivities().first;
      expect(activities, hasLength(1));

      final activity = activities.first;
      expect(activity.id, '1');
      expect(activity.bookCircleTitle, isNull);
      expect(activity.actorName, 'You'); // Is mine, so it's 'You'
      expect(activity.isMine, true);
    });

    test('sendZap handles no npub', () async {
      when(() => identityLocal.readNpub()).thenAnswer((_) async => null);
      await dataSource.sendZap('act1', 10, 'rock'); // Should just return early
    });

    test('sendZap handles empty npub', () async {
      when(() => identityLocal.readNpub()).thenAnswer((_) async => '');
      await dataSource.sendZap('act1', 10, 'rock'); // Should just return early
    });

    test('sendZap executes with npub', () async {
      when(() => identityLocal.readNpub()).thenAnswer((_) async => 'npub1my');
      await dataSource.sendZap(
        'act1',
        10,
        'rock',
      ); // Currently has empty try-catch block
    });
  });
}

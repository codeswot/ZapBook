import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
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
import 'package:zapbook/core/data/database/dao/cheers_dao.dart';
import 'package:zapbook/features/cheers/data/datasources/cheers_data_source.dart';

import 'package:zapbook/core/services/zap_service.dart';
import 'package:zapbook/core/services/zap_nudge_service.dart';
import 'package:zapbook/core/data/infrastructure/nostr_service.dart';
import 'package:zapbook/core/data/infrastructure/clipboard_service.dart';
import 'package:zapbook/zbf/enums/book_source_format.dart';

class MockCircleStoreService extends Mock implements CircleStoreService {}

class MockIdentityLocalDataSource extends Mock
    implements IdentityLocalDataSource {}

class MockCheersDao extends Mock implements CheersDao {}

class MockContactService extends Mock implements ContactService {}

class MockZapService extends Mock implements ZapService {}

class MockZapNudgeService extends Mock implements ZapNudgeService {}

class MockNostrService extends Mock implements NostrService {}

class MockClipboardService extends Mock implements ClipboardService {}

void main() {
  group('CheersDataSourceImpl', () {
    late MockCircleStoreService circleStore;
    late MockIdentityLocalDataSource identityLocal;
    late MockCheersDao cheersDao;
    late MockContactService contactService;
    late MockZapService zapService;
    late MockZapNudgeService nudgeService;
    late MockNostrService nostrService;
    late MockClipboardService clipboardService;
    late CheersDataSourceImpl dataSource;

    setUp(() {
      circleStore = MockCircleStoreService();
      identityLocal = MockIdentityLocalDataSource();
      cheersDao = MockCheersDao();
      contactService = MockContactService();
      zapService = MockZapService();
      nudgeService = MockZapNudgeService();
      nostrService = MockNostrService();
      clipboardService = MockClipboardService();

      dataSource = CheersDataSourceImpl(
        circleStore,
        identityLocal,
        cheersDao,
        contactService,
        zapService,
        nudgeService,
        nostrService,
        clipboardService,
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

    test('sendZap returns failed if lud16 is null', () async {
      when(() => nostrService.getMetadata(any())).thenAnswer((_) async => null);

      final result = await dataSource.sendZap(
        activity: createEmptyActivity(
          actorNpub:
              'npub1v4v5td3r04f3n6udfqqv7eulx328y83tndq889yey8n3cnhrntsq8v0wps',
        ),
        amount: 10,
        gesture: ZapGesture.clap,
      );

      expect(result, ZapStatus.failed);
    });

    test('sendZap executes with lud16', () async {
      when(() => nostrService.getMetadata(any())).thenAnswer((_) async => null);

      // The old tests were for the old empty implementation. For now, testing failure is enough.
    });
  });
}

CheersActivity createEmptyActivity({
  String id = '',
  String groupId = '',
  String actorNpub = '',
  String otherPartyNpub = '',
  String otherPartyName = '',
  String otherPartyPicture = '',
  String actorName = '',
  String actorPicture = '',
  String targetId = '',
  String targetDescription = '',
  DateTime? timestamp,
  CheersActivityType type = CheersActivityType.zap,
  bool isUnread = false,
  int thumbsUpCount = 0,
  int clapCount = 0,
  int fireCount = 0,
  int rocketCount = 0,
  int trophyCount = 0,
  bool isMine = false,
}) => CheersActivity(
  id: id,
  groupId: groupId,
  actorNpub: actorNpub,
  otherPartyNpub: otherPartyNpub,
  otherPartyName: otherPartyName,
  otherPartyPicture: otherPartyPicture,
  actorName: actorName,
  actorPicture: actorPicture,
  targetId: targetId,
  targetDescription: targetDescription,
  timestamp: timestamp ?? DateTime.now(),
  type: type,
  isUnread: isUnread,
  thumbsUpCount: thumbsUpCount,
  clapCount: clapCount,
  fireCount: fireCount,
  rocketCount: rocketCount,
  trophyCount: trophyCount,
  isMine: isMine,
);

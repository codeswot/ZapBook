import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/core/services/decoded_message_cache.dart';
import 'package:zapbook/core/services/milestone_service.dart';
import 'package:zapbook/core/services/marmot_sync_service.dart';
import 'package:zapbook/core/data/dao/cheers_dao.dart';
import 'package:zapbook/features/cheers/data/datasources/cheers_data_source.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';

class MockMarmot extends Mock implements Marmot {}

class MockNdk extends Mock implements Ndk {}

class MockBroadcast extends Mock implements Broadcast {}

class MockNdkBroadcastResponse extends Mock implements NdkBroadcastResponse {}

class MockIdentityLocalDataSource extends Mock
    implements IdentityLocalDataSource {}

class MockMilestoneService extends Mock implements MilestoneService {}

class MockContactService extends Mock implements ContactService {}

class MockDecodedMessageCache extends Mock implements DecodedMessageCache {}

class MockMarmotSyncService extends Mock implements MarmotSyncService {}

class MockCheersDao extends Mock implements CheersDao {}

class MockMarmotGroup extends Mock implements MarmotGroup {}

class FakeNip01Event extends Fake implements Nip01Event {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeNip01Event());
    registerFallbackValue(
      CheersActivity(
        id: '1',
        actorNpub: 's',
        actorName: 'n',
        bookTitle: 'b',
        activityDescription: 'd',
        timestamp: DateTime.now(),
        type: 't',
        isUnread: false,
      ),
    );
    registerFallbackValue(<String>[]);
  });

  late MockMarmot mockMarmot;
  late MockNdk mockNdk;
  late MockIdentityLocalDataSource mockIdentity;
  late MockMilestoneService mockMilestone;
  late MockContactService mockContact;
  late MockDecodedMessageCache mockCache;
  late MockMarmotSyncService mockSync;
  late MockCheersDao mockCheersDao;
  late CheersDataSourceImpl dataSource;

  setUp(() {
    mockMarmot = MockMarmot();
    mockNdk = MockNdk();
    mockIdentity = MockIdentityLocalDataSource();
    mockMilestone = MockMilestoneService();
    mockContact = MockContactService();
    mockCache = MockDecodedMessageCache();
    mockSync = MockMarmotSyncService();
    mockCheersDao = MockCheersDao();

    when(() => mockSync.onSync).thenAnswer((_) => const Stream.empty());
    when(
      () => mockCheersDao.watchActivities(),
    ).thenAnswer((_) => Stream.value([]));
    when(() => mockContact.prime(any())).thenAnswer((_) async => {});

    when(() => mockCheersDao.saveActivity(any())).thenAnswer((_) async {});

    dataSource = CheersDataSourceImpl(
      mockMarmot,
      mockNdk,
      mockIdentity,
      mockMilestone,
      mockContact,
      mockCache,
      mockSync,
      mockCheersDao,
    );
  });

  group('CheersDataSource', () {
    test('bumpLimit increases limit and triggers stream', () async {
      when(() => mockIdentity.readNpub()).thenAnswer(
        (_) async =>
            'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
      );
      when(() => mockMarmot.listGroups()).thenAnswer((_) async => []);

      final stream = dataSource.watchActivities();
      expect(stream, emits(isA<List<CheersActivity>>()));

      dataSource.bumpLimit();
    });

    test('sendDirectZap creates direct zap activity', () async {
      when(() => mockMarmot.sendStructured(any(), any(), any())).thenAnswer(
        (_) async =>
            '{"id": "test", "pubkey": "npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6", "kind": 1, "tags": [], "content": "test", "created_at": 1000}',
      );

      final mockBroadcast = MockBroadcast();
      when(() => mockNdk.broadcast).thenReturn(mockBroadcast);
      when(
        () => mockBroadcast.broadcast(
          nostrEvent: any(named: 'nostrEvent'),
          specificRelays: any(named: 'specificRelays'),
        ),
      ).thenReturn(MockNdkBroadcastResponse());

      when(() => mockIdentity.readNpub()).thenAnswer(
        (_) async =>
            'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
      );

      final future = dataSource.sendDirectZap(
        'groupId',
        'recipientNpub',
        10,
        '👍',
      );

      await expectLater(future, completes);
      verify(() => mockMarmot.sendStructured(any(), any(), any())).called(1);
    });

    test('sendZap creates zap activity', () async {
      when(() => mockIdentity.readNpub()).thenAnswer(
        (_) async =>
            'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
      );
      when(() => mockMarmot.sendStructured(any(), any(), any())).thenAnswer(
        (_) async =>
            '{"id": "test", "pubkey": "npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6", "kind": 1, "tags": [], "content": "test", "created_at": 1000}',
      );

      final mockBroadcast = MockBroadcast();
      when(() => mockNdk.broadcast).thenReturn(mockBroadcast);
      when(
        () => mockBroadcast.broadcast(
          nostrEvent: any(named: 'nostrEvent'),
          specificRelays: any(named: 'specificRelays'),
        ),
      ).thenReturn(MockNdkBroadcastResponse());

      final future = dataSource.sendZap('group1:msg1', 10, '👍');

      await expectLater(future, completes);
    });

    test('watchActivities triggers reload and catchUpGroup', () async {
      when(() => mockIdentity.readNpub()).thenAnswer((_) async => 'npub123');
      final group = MockMarmotGroup();
      when(() => group.id).thenReturn('g1');
      when(() => group.name).thenReturn('[zapbook] test');
      when(() => group.nostrGroupId).thenReturn('nstr1');
      when(() => mockMarmot.listGroups()).thenAnswer((_) async => [group]);
      when(
        () => mockMarmot.getMessages(any(), params: any(named: 'params')),
      ).thenAnswer((_) async => []);

      final requests = MockNdkRequests();
      final req = MockNdkResponse();
      when(() => req.stream).thenAnswer(
        (_) => Stream.value(
          Nip01Event(
            pubKey: 'npub',
            kind: 445,
            tags: [],
            content: 'test',
            createdAt: 100,
          ),
        ),
      );
      when(() => mockNdk.requests).thenReturn(requests);
      when(
        () => requests.query(
          filter: any(named: 'filter'),
          explicitRelays: any(named: 'explicitRelays'),
        ),
      ).thenReturn(req);

      when(() => mockMarmot.processIncoming(any())).thenAnswer((_) async {
        return null;
      });

      final stream = dataSource.watchActivities();
      expect(stream, emits(isA<List<CheersActivity>>()));

      await Future.delayed(const Duration(milliseconds: 100));
      verify(() => mockMarmot.listGroups()).called(greaterThan(0));
    });

    test('watchActivities processes various message types', () async {
      when(() => mockIdentity.readNpub()).thenAnswer((_) async => 'myNpub');
      final group = MockMarmotGroup();
      when(() => group.id).thenReturn('g1');
      when(() => group.name).thenReturn('zapbook-circle-test');
      when(() => group.nostrGroupId).thenReturn('nstr1');

      final recentTimeSecs = PlatformInt64Util.from(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      final msg1 = MarmotMessage(
        id: '1',
        groupId: 'g1',
        senderNpub: 'other',
        timestampSecs: recentTimeSecs,
        media: [],
      );
      final msg2 = MarmotMessage(
        id: '2',
        groupId: 'g1',
        senderNpub: 'other',
        timestampSecs: recentTimeSecs,
        media: [],
      );
      final msg3 = MarmotMessage(
        id: '3',
        groupId: 'g1',
        senderNpub: 'other',
        timestampSecs: recentTimeSecs,
        media: [],
      );
      final msg4 = MarmotMessage(
        id: '4',
        groupId: 'g1',
        senderNpub: 'myNpub',
        timestampSecs: recentTimeSecs,
        media: [],
      );
      final msg5 = MarmotMessage(
        id: '5',
        groupId: 'g1',
        senderNpub: 'other',
        timestampSecs: recentTimeSecs,
        media: [],
      );

      when(() => mockMarmot.listGroups()).thenAnswer((_) async => [group]);
      when(
        () => mockMarmot.getMessages(any(), params: any(named: 'params')),
      ).thenAnswer((_) async => [msg1, msg2, msg3, msg4, msg5]);

      when(
        () => mockCache.get(msg1),
      ).thenReturn({'type': 'zapbook.book.meta', 'title': 'Test Book'});
      when(
        () => mockCache.get(msg2),
      ).thenReturn({'type': 'zapbook.book.milestone'});
      when(() => mockCache.get(msg3)).thenReturn({
        'type': 'zapbook.cheer',
        'activityId': '',
        'reactionType': 'like',
        'amount': 100,
      });
      when(() => mockCache.get(msg4)).thenReturn({
        'type': 'zapbook.zap.nudge',
        'nudgeId': 'nudge1',
        'toNpub': 'myNpub',
        'fromNpub': 'other',
        'createdAtMs': 1000,
      });
      when(() => mockCache.get(msg5)).thenReturn({
        'type': 'zapbook.zap.ready',
        'nudgeId': 'nudge2',
        'toNpub': 'myNpub',
        'fromNpub': 'other',
        'createdAtMs': 1000,
      });

      when(() => mockMilestone.ingestMessage(msg2)).thenReturn(null);
      when(() => mockMilestone.eventsForGroup('g1')).thenReturn([
        MilestoneEvent(
          id: 'ms1',
          groupId: 'g1',
          npub: 'other',
          circleBookId: 'cb1',
          timestamp: DateTime.fromMillisecondsSinceEpoch(1000000),
          progressPct: 50.0,
          completed: false,
          milestoneIdx: 1,
          currentPage: 50,
        ),
      ]);

      when(() => mockSync.onSync).thenAnswer((_) => const Stream.empty());
      when(
        () => mockCheersDao.watchActivities(),
      ).thenAnswer((_) => Stream.value([]));

      final requests = MockNdkRequests();
      when(() => mockNdk.requests).thenReturn(requests);
      final req = MockNdkResponse();
      when(() => req.stream).thenAnswer((_) => const Stream.empty());
      when(
        () => requests.query(
          filter: any(named: 'filter'),
          explicitRelays: any(named: 'explicitRelays'),
        ),
      ).thenReturn(req);

      dataSource.watchActivities().listen((_) {});

      await Future.delayed(const Duration(milliseconds: 100));

      final captures = verify(
        () => mockCheersDao.saveActivity(captureAny()),
      ).captured;
      final activities = captures.cast<CheersActivity>();

      expect(activities, isNotEmpty);
      expect(activities.any((a) => a.type == 'zap'), isTrue);
      expect(activities.any((a) => a.type == 'milestone'), isTrue);
      expect(activities.any((a) => a.type == 'zap_nudge'), isTrue);
      expect(activities.any((a) => a.type == 'zap_ready'), isTrue);
    });
  });
}

class MockNdkRequests extends Mock implements Requests {}

class MockNdkResponse extends Mock implements NdkResponse {}

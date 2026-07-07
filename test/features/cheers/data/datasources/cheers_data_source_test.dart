import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';
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

      final future = dataSource.sendZap('act1', 10, '👍');

      await expectLater(future, completes);
    });
  });
}

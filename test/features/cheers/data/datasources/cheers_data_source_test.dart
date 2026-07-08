import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/core/services/decoded_message_cache.dart';
import 'package:zapbook/core/services/milestone_service.dart';
import 'package:zapbook/core/services/marmot_sync_service.dart';
import 'package:zapbook/core/services/circle_store_service.dart';
import 'package:zapbook/core/data/dao/cheers_dao.dart';
import 'package:zapbook/features/cheers/data/datasources/cheers_data_source.dart';
import 'package:zapbook/core/domain/entities/cheers_activity_message.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';

class MockMarmot extends Mock implements Marmot {}

class MockNdk extends Mock implements Ndk {}

class MockBroadcast extends Mock implements Broadcast {}

class MockNdkBroadcastResponse extends Mock implements NdkBroadcastResponse {}

class MockIdentityLocalDataSource extends Mock
    implements IdentityLocalDataSource {}

class MockCircleStoreService extends Mock implements CircleStoreService {}

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
      CheersActivityMessage(
        id: 'dummy',
        actorNpub: 'dummy',
        activityDescription: 'dummy',
        timestamp: DateTime.now(),
        type: 'dummy',
        isUnread: false,
      ),
    );
    registerFallbackValue(
      CheersActivity(
        id: '1',
        groupId: 'g1',
        isMine: false,
        senderNpub: 's',
        recipientNpub: '',
        targetId: '',
        targetDescription: 'd',
        timestamp: DateTime.now(),
        type: 't',
        isUnread: false,
        recipientDisplayName: '',
        recipientProfilePictureUrl: '',
        senderDisplayName: '',
        senderProfilePictureUrl: '',
      ),
    );
    registerFallbackValue(<String>[]);
  });

  late MockIdentityLocalDataSource mockIdentity;
  late MockMarmotSyncService mockSync;
  late MockCheersDao mockCheersDao;
  late MockCircleStoreService mockCircleStore;
  late MockContactService mockContactService;
  late CheersDataSourceImpl dataSource;

  setUp(() {
    mockIdentity = MockIdentityLocalDataSource();
    mockSync = MockMarmotSyncService();
    mockCheersDao = MockCheersDao();
    mockCircleStore = MockCircleStoreService();
    mockContactService = MockContactService();

    when(() => mockCircleStore.currentCircles).thenReturn([]);

    when(() => mockSync.onSync).thenAnswer((_) => const Stream.empty());
    when(
      () => mockCheersDao.watchActivities(),
    ).thenAnswer((_) => Stream.value([]));

    when(() => mockCheersDao.saveActivity(any())).thenAnswer((_) async {});

    dataSource = CheersDataSourceImpl(
      mockCircleStore,
      mockIdentity,
      mockCheersDao,
      mockContactService,
    );
  });

  group('CheersDataSource', () {
    test('watchActivities returns stream of activities', () async {
      when(() => mockIdentity.readNpub()).thenAnswer(
        (_) async =>
            'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
      );
      final stream = dataSource.watchActivities();
      expect(stream, emitsInOrder([[]]));
    });
  });
}

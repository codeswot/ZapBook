import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:zapbook/core/services/milestone_service.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/group_envelope_service.dart';
import 'package:zapbook/core/data/dao/circle_progress_dao.dart';
import 'package:zapbook/core/data/dao/cheers_dao.dart';
import 'package:zapbook/core/models/circle_member_progress.dart';
import 'package:zapbook/core/domain/entities/cheers_activity_message.dart';
import 'package:ndk/ndk.dart';

class MockMarmot extends Mock implements Marmot {}

class MockIdentityLocalDataSource extends Mock
    implements IdentityLocalDataSource {}

class MockGroupEnvelopeService extends Mock implements GroupEnvelopeService {}

class MockCircleProgressDao extends Mock implements CircleProgressDao {}

class MockCheersDao extends Mock implements CheersDao {}

class FakeNip01Event extends Fake implements Nip01Event {}

class FakeCircleMemberProgress extends Fake implements CircleMemberProgress {}

void main() {
  late MilestoneService service;
  late MockMarmot mockMarmot;
  late MockIdentityLocalDataSource mockIdentity;
  late MockGroupEnvelopeService mockEnvelope;
  late MockCircleProgressDao mockProgressDao;
  late MockCheersDao mockCheersDao;

  setUpAll(() {
    registerFallbackValue(FakeNip01Event());
    registerFallbackValue(FakeCircleMemberProgress());
    registerFallbackValue(
      CheersActivityMessage(
        id: '1',
        actorNpub: 'a',
        activityDescription: 'b',
        timestamp: DateTime.now(),
        type: 'c',
        isUnread: false,
      ),
    );
  });

  setUp(() {
    mockMarmot = MockMarmot();
    mockIdentity = MockIdentityLocalDataSource();
    mockEnvelope = MockGroupEnvelopeService();
    mockProgressDao = MockCircleProgressDao();
    mockCheersDao = MockCheersDao();

    when(() => mockIdentity.readNpub()).thenAnswer(
      (_) async =>
          'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
    );
    when(
      () => mockProgressDao.getProgress(
        groupId: any(named: 'groupId'),
        bookId: any(named: 'bookId'),
        pubKey: any(named: 'pubKey'),
      ),
    ).thenAnswer((_) async => null);
    when(
      () => mockProgressDao.upsertProgress(any()),
    ).thenAnswer((_) async => {});
    when(() => mockCheersDao.saveActivity(any())).thenAnswer((_) async => {});
    when(() => mockMarmot.sendStructured(any(), any(), any())).thenAnswer(
      (_) async =>
          '{"pubkey": "a", "kind": 1, "tags": [], "content": "", "created_at": 0}',
    );
    when(() => mockEnvelope.publish(any())).thenAnswer((_) async => {});

    service = MilestoneService(
      mockMarmot,
      mockIdentity,
      mockEnvelope,
      mockProgressDao,
      mockCheersDao,
    );
  });

  test('reportProgress debounces and publishes', () async {
    service.reportProgress(
      circleDirId: 'dir1',
      groupId: 'g1',
      currentPage: 1,
      currentWordCount: 100,
      totalWords: 1000,
      fraction: 0.1,
    );

    await Future.delayed(const Duration(milliseconds: 100));
    // Should not have sent structured message yet due to debounce
    verifyNever(() => mockMarmot.sendStructured(any(), any(), any()));

    service.flushProgress('dir1');
    await Future.delayed(const Duration(milliseconds: 100));

    verify(() => mockMarmot.sendStructured(any(), any(), any())).called(1);
    verify(() => mockProgressDao.upsertProgress(any())).called(1);
  });

  test('reportProgress sends immediately on significant milestone', () async {
    service.reportProgress(
      circleDirId: 'dir1',
      groupId: 'g1',
      currentPage: 1,
      currentWordCount: 100,
      totalWords: 1000,
      fraction: 0.1,
      milestonesReached: 1, // This is significant
    );

    await Future.delayed(const Duration(milliseconds: 100));

    verify(() => mockMarmot.sendStructured(any(), any(), any())).called(1);
    verify(() => mockProgressDao.upsertProgress(any())).called(1);
  });

  test('reportProgress sends immediately on book completed', () async {
    service.reportProgress(
      circleDirId: 'dir1',
      groupId: 'g1',
      currentPage: 10,
      currentWordCount: 1000,
      totalWords: 1000,
      fraction: 1.0,
      bookCompleted: true, // This is significant
    );

    await Future.delayed(const Duration(milliseconds: 100));

    verify(() => mockMarmot.sendStructured(any(), any(), any())).called(1);
    verify(() => mockProgressDao.upsertProgress(any())).called(1);
  });

  test('closeBook flushes progress', () async {
    service.reportProgress(
      circleDirId: 'dir1',
      groupId: 'g1',
      currentPage: 1,
      currentWordCount: 100,
      totalWords: 1000,
      fraction: 0.1,
    );

    service.closeBook('dir1');
    await Future.delayed(const Duration(milliseconds: 100));

    verify(() => mockMarmot.sendStructured(any(), any(), any())).called(1);
  });
}

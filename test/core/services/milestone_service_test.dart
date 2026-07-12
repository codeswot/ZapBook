import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ndk/ndk.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:zapbook/core/services/milestone_service.dart';
import 'package:zapbook/core/services/decoded_message_cache.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';

import 'package:zapbook/core/data/dao/circle_progress_dao.dart';
import 'package:zapbook/core/data/dao/cheers_dao.dart';
import 'package:zapbook/core/domain/entities/cheers_activity_message.dart';
import 'package:zapbook/core/models/circle_member_progress.dart';

class MockMarmot extends Mock implements Marmot {}

class MockNdk extends Mock implements Ndk {}

class MockIdentityLocalDataSource extends Mock
    implements IdentityLocalDataSource {}

class MockDecodedMessageCache extends Mock implements DecodedMessageCache {}

class MockCircleProgressDao extends Mock implements CircleProgressDao {}

class MockBroadcast extends Mock implements Broadcast {}

class FakeNip01Event extends Fake implements Nip01Event {}

class FakeNdkBroadcastResponse extends Fake implements NdkBroadcastResponse {}

class MockMarmotGroup extends Mock implements MarmotGroup {}

class FakeMarmotMessage extends Fake implements MarmotMessage {}

class FakeCircleMemberProgress extends Fake implements CircleMemberProgress {}

class MockCheersDao extends Mock implements CheersDao {}

class FakeCheersActivityMessage extends Fake implements CheersActivityMessage {}

void main() {
  late MilestoneService service;
  late MockMarmot mockMarmot;
  late MockNdk mockNdk;
  late MockIdentityLocalDataSource mockIdentity;
  late MockDecodedMessageCache mockCache;
  late MockCircleProgressDao mockDao;
  late MockCheersDao mockCheersDao;
  late MockBroadcast mockBroadcast;

  setUpAll(() {
    registerFallbackValue(FakeNip01Event());
    registerFallbackValue(FakeMarmotMessage());
    registerFallbackValue(FakeCircleMemberProgress());
    registerFallbackValue(FakeCheersActivityMessage());
  });

  setUp(() {
    mockMarmot = MockMarmot();
    mockNdk = MockNdk();
    mockIdentity = MockIdentityLocalDataSource();
    mockCache = MockDecodedMessageCache();
    mockDao = MockCircleProgressDao();
    mockCheersDao = MockCheersDao();
    mockBroadcast = MockBroadcast();

    when(() => mockNdk.broadcast).thenReturn(mockBroadcast);
    when(() => mockMarmot.listGroups()).thenAnswer((_) async => []);
    when(
      () => mockDao.getProgress(
        groupId: any(named: 'groupId'),
        bookId: any(named: 'bookId'),
        pubKey: any(named: 'pubKey'),
      ),
    ).thenAnswer((_) async => null);
    when(() => mockDao.upsertProgress(any())).thenAnswer((_) async => {});
    when(() => mockCheersDao.saveActivity(any())).thenAnswer((_) async => {});
    when(() => mockIdentity.readNpub()).thenAnswer(
      (_) async =>
          'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
    );

    service = MilestoneService(
      mockMarmot,
      mockIdentity,
      GroupEnvelopeService(mockNdk, mockIdentity, mockCache),
      mockDao,
      mockCheersDao,
    );
  });

  test('ingestMessage processes progress correctly', () {
    final msg = MarmotMessage(
      id: '1',
      groupId: 'g1',
      senderNpub:
          'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
      timestampSecs: 1000,
      payloadJson: '{"type":"zapbook.book.progress"}',
      media: const [],
    );

    when(() => mockCache.get(any())).thenReturn({
      'type': 'zapbook.book.progress',
      'circleBookId': 'book1',
      'fraction': 0.5,
      'currentPage': 5,
      'currentWordCount': 500,
      'totalWordCount': 1000,
    });

    service.ingestMessage(msg);

    final progress = service.membersOf(
      'book1',
    )['npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6'];
    expect(progress, isNotNull);
    expect(progress!.fraction, 0.5);
    expect(progress.currentPage, 5);
  });

  test('ingestMessage processes milestone correctly', () {
    final msg = MarmotMessage(
      id: '2',
      groupId: 'g1',
      senderNpub:
          'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
      timestampSecs: 1000,
      payloadJson: '{"type":"zapbook.book.milestone"}',
      media: const [],
    );

    when(() => mockCache.get(any())).thenReturn({
      'type': 'zapbook.book.milestone',
      'circleBookId': 'book1',
      'milestone_idx': 1,
      'current_page': 5,
      'progress_pct': 50.0,
      'current_word_count': 500,
      'total_word_count': 1000,
    });

    service.ingestMessage(msg);

    final milestones = service.getMilestones('book1');
    expect(milestones.length, 1);
    expect(milestones.first.milestoneIdx, 1);

    final events = service.milestoneEvents();
    expect(events.length, 1);
    expect(events.first.milestoneIdx, 1);
  });

  test('ingestMessage processes completed correctly', () {
    final msg = MarmotMessage(
      id: '3',
      groupId: 'g1',
      senderNpub:
          'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
      timestampSecs: 1000,
      payloadJson: '{"type":"zapbook.book.completed"}',
      media: const [],
    );

    when(
      () => mockCache.get(any()),
    ).thenReturn({'type': 'zapbook.book.completed', 'circleBookId': 'book1'});

    service.ingestMessage(msg);

    final progress = service.membersOf(
      'book1',
    )['npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6'];
    expect(progress, isNotNull);
    expect(progress!.fraction, 1.0);
    expect(service.completedBooksCount, 1);
  });

  test('updateProgress debounces and publishes progress', () async {
    final group = MockMarmotGroup();
    when(() => group.id).thenReturn('g1');
    when(() => group.name).thenReturn('zapbook-book-book1');

    when(() => mockMarmot.listGroups()).thenAnswer((_) async => [group]);
    when(() => mockMarmot.sendStructured(any(), any(), any())).thenAnswer(
      (_) async => jsonEncode({
        'pubkey':
            'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
        'kind': 1,
        'content': 'test',
        'created_at': 123,
        'tags': [],
      }),
    );
    when(
      () => mockBroadcast.broadcast(
        nostrEvent: any(named: 'nostrEvent'),
        specificRelays: any(named: 'specificRelays'),
      ),
    ).thenReturn(FakeNdkBroadcastResponse());

    service.updateProgress(
      circleBookId: 'book1',
      currentPage: 1,
      currentWordCount: 100,
      totalWords: 1000,
      fraction: 0.1,
    );

    service.flushProgress('book1');
    await Future.delayed(const Duration(milliseconds: 500));

    verify(() => mockMarmot.sendStructured(any(), any(), any())).called(1);
  });

  test('markCompleted debounces and publishes progress', () async {
    final group = MockMarmotGroup();
    when(() => group.id).thenReturn('g1');
    when(() => group.name).thenReturn('zapbook-book-book1');
    when(() => mockMarmot.listGroups()).thenAnswer((_) async => [group]);
    when(() => mockMarmot.sendStructured(any(), any(), any())).thenAnswer(
      (_) async => jsonEncode({
        'pubkey':
            'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
        'kind': 1,
        'content': 'test',
        'created_at': 123,
        'tags': [],
      }),
    );
    when(
      () => mockBroadcast.broadcast(
        nostrEvent: any(named: 'nostrEvent'),
        specificRelays: any(named: 'specificRelays'),
      ),
    ).thenReturn(FakeNdkBroadcastResponse());

    await service.markCompleted('book1', totalWords: 1000);

    final progress = service.progressOf('book1');
    expect(progress, isNotNull);
    expect(progress!.fraction, 1.0);
    expect(progress.currentWordCount, 1000);
  });

  test('publishBookCompleted publishes message', () async {
    final group = MockMarmotGroup();
    when(() => group.id).thenReturn('g1');
    when(() => group.name).thenReturn('zapbook-book-book1');
    when(() => mockMarmot.listGroups()).thenAnswer((_) async => [group]);
    when(() => mockMarmot.sendStructured(any(), any(), any())).thenAnswer(
      (_) async => jsonEncode({
        'pubkey':
            'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
        'kind': 1,
        'content': 'test',
        'created_at': 123,
        'tags': [],
      }),
    );
    when(
      () => mockBroadcast.broadcast(
        nostrEvent: any(named: 'nostrEvent'),
        specificRelays: any(named: 'specificRelays'),
      ),
    ).thenReturn(FakeNdkBroadcastResponse());

    await service.publishBookCompleted('book1');

    final progress = service.membersOf(
      'book1',
    )['npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6'];
    expect(progress, isNotNull);
    expect(progress!.fraction, 1.0);
  });

  test('publishMilestone publishes correctly', () async {
    final group = MockMarmotGroup();
    when(() => group.id).thenReturn('g1');
    when(() => group.name).thenReturn('zapbook-book-book1');
    when(() => mockMarmot.listGroups()).thenAnswer((_) async => [group]);
    when(() => mockMarmot.sendStructured(any(), any(), any())).thenAnswer(
      (_) async => jsonEncode({
        'pubkey':
            'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
        'kind': 1,
        'content': 'test',
        'created_at': 123,
        'tags': [],
      }),
    );
    when(
      () => mockBroadcast.broadcast(
        nostrEvent: any(named: 'nostrEvent'),
        specificRelays: any(named: 'specificRelays'),
      ),
    ).thenReturn(FakeNdkBroadcastResponse());

    await service.publishMilestone(
      circleBookId: 'book1',
      milestoneIdx: 1,
      currentWordCount: 100,
      totalWordCount: 1000,
      progressPct: 10.0,
      currentPage: 1,
      sessionEngagedMs: 5000,
    );

    final milestones = service.getMilestones('book1');
    expect(milestones.isNotEmpty, true);
    expect(milestones.first.milestoneIdx, 1);
  });

  test('syncAll fetches and ingests messages', () async {
    final group = MockMarmotGroup();
    when(() => group.id).thenReturn('g1');
    when(() => group.name).thenReturn('zapbook-book-book1');
    when(() => mockMarmot.listGroups()).thenAnswer((_) async => [group]);

    final msg = MarmotMessage(
      id: '1',
      groupId: 'g1',
      senderNpub:
          'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
      timestampSecs: 1000,
      payloadJson: '{"type":"zapbook.book.progress"}',
      media: const [],
    );
    when(() => mockMarmot.getMessages('g1')).thenAnswer((_) async => [msg]);

    when(() => mockCache.get(any())).thenReturn({
      'type': 'zapbook.book.progress',
      'circleBookId': 'book1',
      'fraction': 0.8,
      'currentPage': 8,
      'currentWordCount': 800,
      'totalWordCount': 1000,
    });

    await service.syncAll();

    final members = service.membersOf('book1');
    expect(
      members['npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6']
          ?.fraction,
      0.8,
    );
  });

  test('loadMembers fetches and returns members', () async {
    final group = MockMarmotGroup();
    when(() => group.id).thenReturn('g1');
    when(() => group.name).thenReturn('zapbook-book-book1');
    when(() => mockMarmot.listGroups()).thenAnswer((_) async => [group]);

    final msg = MarmotMessage(
      id: '1',
      groupId: 'g1',
      senderNpub:
          'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
      timestampSecs: 1000,
      payloadJson: '{"type":"zapbook.book.progress"}',
      media: const [],
    );
    when(() => mockMarmot.getMessages('g1')).thenAnswer((_) async => [msg]);

    when(() => mockCache.get(any())).thenReturn({
      'type': 'zapbook.book.progress',
      'circleBookId': 'book1',
      'fraction': 0.9,
      'currentPage': 9,
      'currentWordCount': 900,
      'totalWordCount': 1000,
    });

    final members = await service.loadMembers('book1');
    expect(
      members['npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6']
          ?.fraction,
      0.9,
    );
  });

  test('watchProgress and watchMembers emit correctly', () async {
    final progressStream = service.watchProgress('book1');
    final membersStream = service.watchMembers('book1');

    final pFuture = expectLater(progressStream, emits(isA<BookProgress>()));
    final mFuture = expectLater(
      membersStream,
      emits(isA<Map<String, BookProgress>>()),
    );

    service.updateProgress(
      circleBookId: 'book1',
      currentPage: 2,
      currentWordCount: 200,
      totalWords: 1000,
      fraction: 0.2,
    );

    await Future.wait([pFuture, mFuture]);
  });
}

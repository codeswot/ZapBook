import 'dart:async';
import 'package:ndk/ndk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/services/nwc_service.dart';
import 'package:zapbook/core/services/nostr_service.dart';
import 'package:zapbook/core/services/zap_confirmation_service.dart';
import 'package:zapbook/core/services/zap_nudge_service.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/services/zap_service.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';
import 'package:zapbook/features/cheers/domain/usecases/send_cheers_zap.dart';
import 'package:zapbook/features/cheers/domain/usecases/watch_cheers_activities.dart';
import 'package:zapbook/features/cheers/domain/usecases/load_more_cheers_activities.dart';
import 'package:zapbook/features/cheers/presentation/bloc/cheers_cubit.dart';
import 'package:zapbook/features/cheers/presentation/bloc/cheers_state.dart';

class MockWatchCheersActivities extends Mock implements WatchCheersActivities {}

class MockSendCheersZap extends Mock implements SendCheersZap {}

class MockLoadMoreCheersActivities extends Mock
    implements LoadMoreCheersActivities {}

class MockZapService extends Mock implements ZapService {}

class MockZapNudgeService extends Mock implements ZapNudgeService {}

class FakeNostrService extends Fake implements NostrService {
  @override
  Future<Metadata?> getMetadata(
    String pubkey, {
    bool forceRefresh = false,
  }) async {
    return null;
  }
}

class FakeNostrServiceWithLud16 extends Fake implements NostrService {
  @override
  Future<Metadata?> getMetadata(
    String pubkey, {
    bool forceRefresh = false,
  }) async {
    final meta = Metadata(pubKey: pubkey)..lud16 = 'test@example.com';
    return meta;
  }
}

class MockNwcService extends Mock implements NwcService {}

class MockZapConfirmationService extends Mock
    implements ZapConfirmationService {}

class FakePendingZapRecord extends Fake implements PendingZapRecord {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakePendingZapRecord());
    registerFallbackValue(ZapGesture.thumbsUp);
    registerFallbackValue(
      const ZapResult(
        zapRequestId: '123',
        invoice: 'lnbc123',
        recipientPubkey: 'pubkey',
        amountSats: 10,
        gesture: ZapGesture.thumbsUp,
        targetEventId: 'eventId',
      ),
    );
  });

  late MockWatchCheersActivities watchCheersActivities;
  late MockSendCheersZap sendCheersZap;
  late MockLoadMoreCheersActivities loadMoreCheersActivities;
  late MockZapService zapService;
  late MockZapNudgeService nudgeService;
  late NostrService nostrService;
  late MockNwcService nwcService;
  late MockZapConfirmationService zapConfirmationService;

  late StreamController<List<CheersActivity>> activitiesController;

  setUp(() {
    watchCheersActivities = MockWatchCheersActivities();
    sendCheersZap = MockSendCheersZap();
    loadMoreCheersActivities = MockLoadMoreCheersActivities();
    zapService = MockZapService();
    nudgeService = MockZapNudgeService();
    nostrService = FakeNostrService();
    nwcService = MockNwcService();
    zapConfirmationService = MockZapConfirmationService();

    activitiesController = StreamController<List<CheersActivity>>.broadcast();

    when(
      () => watchCheersActivities(),
    ).thenAnswer((_) => activitiesController.stream);
  });

  tearDown(() {
    activitiesController.close();
  });

  CheersCubit createCubit() {
    return CheersCubit(
      watchCheersActivities,
      sendCheersZap,
      loadMoreCheersActivities,
      zapService,
      nudgeService,
      nostrService,
      nwcService,
      zapConfirmationService,
    );
  }

  test('initial state is CheersLoading', () {
    final cubit = createCubit();
    expect(cubit.state, const CheersLoading());
  });

  test('emits CheersLoaded when stream yields activities', () async {
    final cubit = createCubit();

    final activity = CheersActivity(
      id: '1',
      type: 'milestone',
      actorNpub: 'npub_alice',
      actorName: 'Alice',
      bookTitle: 'Test Book',
      activityDescription: 'Reached a milestone',
      timestamp: DateTime.now(),
      isUnread: false,
      zapAmount: 100,
    );
    activitiesController.add([activity]);

    await Future.delayed(const Duration(milliseconds: 300));

    expect(cubit.state, isA<CheersLoaded>());
    final state = cubit.state as CheersLoaded;
    expect(state.activities.length, 1);
    expect(state.activities.first.id, '1');
  });

  test('setFilter filters activities correctly', () async {
    final cubit = createCubit();

    final activities = [
      CheersActivity(
        id: '1',
        type: 'milestone',
        actorNpub: 'npub_alice',
        actorName: 'Alice',
        bookTitle: 'Test Book',
        activityDescription: 'Reached a milestone',
        timestamp: DateTime.now(),
        isUnread: false,
        zapAmount: 100,
      ),
      CheersActivity(
        id: '2',
        type: 'zap',
        actorNpub: 'npub_bob',
        actorName: 'Bob',
        bookTitle: 'Test Book',
        activityDescription: 'Zapped you',
        zapRecipientNpub: 'npub123',
        timestamp: DateTime.now(),
        isUnread: true,
        zapAmount: 50,
      ),
    ];

    activitiesController.add(activities);
    await Future.delayed(const Duration(milliseconds: 300));

    cubit.setFilter('Zaps');

    expect(cubit.state, isA<CheersLoaded>());
    final state = cubit.state as CheersLoaded;
    expect(state.activeFilter, 'Zaps');
    expect(state.activities.length, 1);
    expect(state.activities.first.type, 'zap');
  });

  test('loadMore triggers LoadMoreCheersActivities', () {
    when(() => loadMoreCheersActivities()).thenReturn(null);
    final cubit = createCubit();
    cubit.loadMore();
    verify(() => loadMoreCheersActivities()).called(1);
  });

  group('performZap', () {
    final activity = CheersActivity(
      id: 'group1:npub123',
      type: 'milestone',
      actorNpub:
          'npub1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqujme',
      actorName: 'Bob',
      bookTitle: 'Title',
      activityDescription: 'desc',
      timestamp: DateTime.now(),
      isUnread: false,
    );

    test('ignores mine activities', () async {
      final cubit = createCubit();
      final mineActivity = CheersActivity(
        id: 'group1:npub123',
        type: 'mine',
        actorNpub:
            'npub1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqujme',
        actorName: 'Bob',
        bookTitle: 'Title',
        activityDescription: 'desc',
        timestamp: DateTime.now(),
        isUnread: false,
      );
      await cubit.performZap(
        activity: mineActivity,
        gesture: ZapGesture.thumbsUp,
        amount: 10,
      );
      expect(cubit.state, const CheersLoading()); // State remains unchanged
    });

    test('emits CheersNudgeRequired when lud16 is empty', () async {
      final cubit = createCubit();

      when(
        () => nudgeService.nudge(
          groupId: any(named: 'groupId'),
          toNpub: any(named: 'toNpub'),
        ),
      ).thenAnswer((_) => Future.value());

      await cubit.performZap(
        activity: activity,
        gesture: ZapGesture.thumbsUp,
        amount: 10,
      );

      expect(cubit.state, isA<CheersNudgeRequired>());
    });

    test(
      'emits CheersZapInfo when lud16 is valid and sendCheersZap succeeds',
      () async {
        nostrService = FakeNostrServiceWithLud16();
        final cubit = createCubit();

        when(
          () => sendCheersZap.call(
            activityId: any(named: 'activityId'),
            amount: any(named: 'amount'),
            reactionType: any(named: 'reactionType'),
          ),
        ).thenAnswer((_) => Future.value());
        when(() => nwcService.isConnected).thenReturn(false);
        when(
          () => zapService.send(
            recipientLud16: any(named: 'recipientLud16'),
            recipientPubkey: any(named: 'recipientPubkey'),
            targetEventId: any(named: 'targetEventId'),
            gesture: any(named: 'gesture'),
            customSats: any(named: 'customSats'),
            comment: any(named: 'comment'),
            circleId: any(named: 'circleId'),
          ),
        ).thenAnswer(
          (_) => Future.value(
            const ZapResult(
              zapRequestId: '123',
              invoice: 'lnbc123',
              recipientPubkey: 'pubkey',
              amountSats: 10,
              gesture: ZapGesture.thumbsUp,
              targetEventId: 'eventId',
            ),
          ),
        );
        when(
          () => zapService.payZap(any()),
        ).thenAnswer((_) => Future.value(true));
        when(
          () => zapConfirmationService.watch(any()),
        ).thenAnswer((_) => Future.value());

        await cubit.performZap(
          activity: activity,
          gesture: ZapGesture.thumbsUp,
          amount: 10,
        );

        expect(cubit.state, isA<CheersZapSuccess>());
      },
    );
  });
}

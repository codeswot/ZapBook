import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/services/nwc_service.dart';
import 'package:zapbook/core/services/nostr_service.dart';
import 'package:zapbook/core/services/zap_confirmation_service.dart';
import 'package:zapbook/core/services/zap_nudge_service.dart';
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

class MockNostrService extends Mock implements NostrService {}

class MockNwcService extends Mock implements NwcService {}

class MockZapConfirmationService extends Mock
    implements ZapConfirmationService {}

void main() {
  late MockWatchCheersActivities watchCheersActivities;
  late MockSendCheersZap sendCheersZap;
  late MockLoadMoreCheersActivities loadMoreCheersActivities;
  late MockZapService zapService;
  late MockZapNudgeService nudgeService;
  late MockNostrService nostrService;
  late MockNwcService nwcService;
  late MockZapConfirmationService zapConfirmationService;

  late StreamController<List<CheersActivity>> activitiesController;

  setUp(() {
    watchCheersActivities = MockWatchCheersActivities();
    sendCheersZap = MockSendCheersZap();
    loadMoreCheersActivities = MockLoadMoreCheersActivities();
    zapService = MockZapService();
    nudgeService = MockZapNudgeService();
    nostrService = MockNostrService();
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
}

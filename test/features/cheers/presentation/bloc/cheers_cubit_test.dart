import 'dart:async';
import 'package:ndk/ndk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/services/nostr_service.dart';
import 'package:zapbook/core/services/zap_nudge_service.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';
import 'package:zapbook/features/cheers/domain/usecases/watch_cheers_activities.dart';
import 'package:zapbook/features/cheers/presentation/bloc/cheers_cubit.dart';
import 'package:zapbook/features/cheers/presentation/bloc/cheers_state.dart';

class MockWatchCheersActivities extends Mock implements WatchCheersActivities {}

class MockZapNudgeService extends Mock implements ZapNudgeService {}

class FakeNostrService extends Fake implements NostrService {
  @override
  String? get pubkey => 'testPubkey';
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

void main() {
  late MockWatchCheersActivities watchCheersActivities;
  late MockZapNudgeService nudgeService;
  late NostrService nostrService;

  late StreamController<List<CheersActivity>> activitiesController;

  setUp(() {
    watchCheersActivities = MockWatchCheersActivities();
    nudgeService = MockZapNudgeService();
    nostrService = FakeNostrService();

    activitiesController = StreamController<List<CheersActivity>>.broadcast();

    when(
      () => watchCheersActivities(),
    ).thenAnswer((_) => activitiesController.stream);
  });

  tearDown(() {
    activitiesController.close();
  });

  CheersCubit createCubit() {
    return CheersCubit(watchCheersActivities, nudgeService, nostrService);
  }

  test('initial state is CheersLoading', () {
    final cubit = createCubit();
    expect(cubit.state, const CheersLoading());
  });

  test('emits CheersLoaded when stream yields activities', () async {
    final cubit = createCubit();

    final activity = CheersActivity(
      id: '1',
      groupId: 'g1',
      senderNpub: 'actor',
      recipientNpub: '',
      targetId: '',
      targetDescription: 'desc',
      timestamp: DateTime.now(),
      type: 'zap',
      isUnread: false,
      isMine: false,
      recipientDisplayName: '',
      recipientProfilePictureUrl: '',
      senderDisplayName: '',
      senderProfilePictureUrl: '',
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
        groupId: 'g1',
        senderNpub: 's',
        recipientNpub: '',
        targetId: '',
        targetDescription: 'd',
        timestamp: DateTime.now(),
        type: 't',
        isUnread: false,
        isMine: false,
        recipientDisplayName: '',
        recipientProfilePictureUrl: '',
        senderDisplayName: '',
        senderProfilePictureUrl: '',
        zapAmount: 100,
      ),
      CheersActivity(
        id: '2',
        groupId: 'g1',
        senderNpub: 'actor',
        recipientNpub: 'recipient',
        targetId: '',
        targetDescription: 'desc',
        timestamp: DateTime.now(),
        type: 'zap',
        isUnread: false,
        isMine: false,
        recipientDisplayName: '',
        recipientProfilePictureUrl: '',
        senderDisplayName: '',
        senderProfilePictureUrl: '',
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

  group('performZap', () {
    final activity = CheersActivity(
      id: 'group1:npub123',
      groupId: 'g1',
      senderNpub:
          'npub1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqujme',
      recipientNpub: '',
      targetId: '',
      targetDescription: 'desc',
      timestamp: DateTime.now(),
      type: 'milestone',
      isUnread: false,
      isMine: false,
      recipientDisplayName: '',
      recipientProfilePictureUrl: '',
      senderDisplayName: '',
      senderProfilePictureUrl: '',
    );

    test('ignores mine activities', () async {
      final cubit = createCubit();
      final mineActivity = CheersActivity(
        id: 'group1:npub123',
        groupId: 'g1',
        senderNpub:
            'npub1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqujme',
        recipientNpub: '',
        targetId: '',
        targetDescription: 'desc',
        timestamp: DateTime.now(),
        type: 'zap',
        isUnread: false,
        isMine: true,
        recipientDisplayName: '',
        recipientProfilePictureUrl: '',
        senderDisplayName: '',
        senderProfilePictureUrl: '',
      );
      await cubit.performZap(
        actorName: 'Test',
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
        actorName: 'Test',
        activity: activity,
        gesture: ZapGesture.thumbsUp,
        amount: 10,
      );

      expect(cubit.state, isA<CheersNudgeRequired>());
    });
  });
}

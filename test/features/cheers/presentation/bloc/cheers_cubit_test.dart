import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/domain/entities/cheers_activity_type.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';
import 'package:zapbook/features/cheers/domain/usecases/cheers_usecases.dart';
import 'package:zapbook/features/cheers/presentation/bloc/cheers_cubit.dart';
import 'package:zapbook/features/cheers/presentation/bloc/cheers_state.dart';
import 'package:zapbook/core/domain/entities/zap_status.dart';

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

class MockWatchCheersActivitiesUseCase extends Mock
    implements WatchCheersActivitiesUseCase {}

class MockSendCheersZapUseCase extends Mock implements SendCheersZapUseCase {}

class MockSendCheersNudgeUseCase extends Mock
    implements SendCheersNudgeUseCase {}

class MockLookupLud16UseCase extends Mock implements LookupLud16UseCase {}

class MockCopyCheersActivityTextUseCase extends Mock
    implements CopyCheersActivityTextUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(ZapGesture.clap);
    registerFallbackValue(createEmptyActivity());
  });

  late MockWatchCheersActivitiesUseCase watchCheersActivities;
  late MockSendCheersZapUseCase sendCheersZap;
  late MockSendCheersNudgeUseCase sendCheersNudge;
  late MockLookupLud16UseCase lookupLud16;
  late MockCopyCheersActivityTextUseCase copyText;
  late StreamController<List<CheersActivity>> activitiesController;

  setUp(() {
    watchCheersActivities = MockWatchCheersActivitiesUseCase();
    sendCheersZap = MockSendCheersZapUseCase();
    sendCheersNudge = MockSendCheersNudgeUseCase();
    lookupLud16 = MockLookupLud16UseCase();
    copyText = MockCopyCheersActivityTextUseCase();
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
      sendCheersNudge,
      lookupLud16,
      copyText,
    );
  }

  test('initial state is CheersLoading', () {
    final cubit = createCubit();
    expect(cubit.state, isA<CheersLoading>());
    cubit.close();
  });

  group('filtering', () {
    test('emits CheersLoaded on stream update', () async {
      final cubit = createCubit();

      final activity = createEmptyActivity(
        id: '1',
        type: CheersActivityType.zap,
      );

      activitiesController.add([activity]);

      await expectLater(
        cubit.stream,
        emitsInOrder([
          isA<CheersLoaded>().having((s) => s.activities.length, 'length', 1),
        ]),
      );

      cubit.close();
    });
  });

  group('performZap', () {
    test('does nothing if activity is mine', () async {
      final cubit = createCubit();
      final activity = createEmptyActivity(isMine: true);

      await cubit.performZap(
        activity: activity,
        gesture: ZapGesture.clap,
        amount: 10,
      );

      verifyNever(() => lookupLud16(any()));
      verifyNever(
        () => sendCheersZap(
          activity: any(named: 'activity'),
          gesture: any(named: 'gesture'),
          amount: any(named: 'amount'),
        ),
      );
      cubit.close();
    });

    test('emits CheersNudgeRequired if no lud16', () async {
      final cubit = createCubit();
      final activity = createEmptyActivity(
        actorNpub:
            'npub1v4v5td3r04f3n6udfqqv7eulx328y83tndq889yey8n3cnhrntsq8v0wps',
        isMine: false,
      );

      when(() => lookupLud16(any())).thenAnswer((_) async => null);
      when(
        () => sendCheersNudge.sendNudge(
          groupId: any(named: 'groupId'),
          toNpub: any(named: 'toNpub'),
        ),
      ).thenAnswer((_) async {});

      final states = <CheersState>[];
      cubit.stream.listen(states.add);

      await cubit.performZap(
        activity: activity,
        gesture: ZapGesture.clap,
        amount: 10,
      );

      await Future.delayed(Duration.zero);
      expect(states.last, isA<CheersNudgeRequired>());
      verify(
        () => sendCheersNudge.sendNudge(
          groupId: activity.groupId,
          toNpub: activity.actorNpub,
        ),
      ).called(1);

      cubit.close();
    });

    test('emits CheersZapSuccess when zap succeeds', () async {
      final cubit = createCubit();
      final activity = createEmptyActivity(
        actorNpub:
            'npub1v4v5td3r04f3n6udfqqv7eulx328y83tndq889yey8n3cnhrntsq8v0wps',
        isMine: false,
      );

      when(() => lookupLud16(any())).thenAnswer((_) async => 'test@lud16.com');
      when(
        () => sendCheersZap(
          activity: any(named: 'activity'),
          gesture: any(named: 'gesture'),
          amount: any(named: 'amount'),
          comment: any(named: 'comment'),
        ),
      ).thenAnswer((_) async => ZapStatus.paidNwc);

      final states = <CheersState>[];
      cubit.stream.listen(states.add);

      await cubit.performZap(
        activity: activity,
        gesture: ZapGesture.clap,
        amount: 10,
      );

      await Future.delayed(Duration.zero);
      expect(states.last, isA<CheersZapSuccess>());
      cubit.close();
    });
  });

  group('performNudge', () {
    test('emits CheersNudgeSetupRequired if my lud16 is empty', () async {
      final cubit = createCubit();
      final activity = createEmptyActivity();

      when(
        () => sendCheersNudge.getMyPubkey(),
      ).thenAnswer((_) async => 'mypubkey');
      when(() => lookupLud16('mypubkey')).thenAnswer((_) async => '');

      final states = <CheersState>[];
      cubit.stream.listen(states.add);

      await cubit.performNudge(activity);

      await Future.delayed(Duration.zero);
      expect(states.last, isA<CheersNudgeSetupRequired>());
      cubit.close();
    });

    test('emits CheersNudgeSuccess when nudge succeeds', () async {
      final cubit = createCubit();
      final activity = createEmptyActivity();

      when(
        () => sendCheersNudge.getMyPubkey(),
      ).thenAnswer((_) async => 'mypubkey');
      when(
        () => lookupLud16('mypubkey'),
      ).thenAnswer((_) async => 'mylud16@example.com');
      when(
        () => sendCheersNudge.sendNudgeReady(
          groupId: any(named: 'groupId'),
          nudgeId: any(named: 'nudgeId'),
          toNpub: any(named: 'toNpub'),
        ),
      ).thenAnswer((_) async {});

      final states = <CheersState>[];
      cubit.stream.listen(states.add);

      await cubit.performNudge(activity);

      await Future.delayed(Duration.zero);
      expect(states.last, isA<CheersNudgeSuccess>());
      cubit.close();
    });
  });
}

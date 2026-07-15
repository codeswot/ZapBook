import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/domain/entities/cheers_activity_type.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';
import 'package:zapbook/features/cheers/domain/cheers_note_composer.dart';
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

class MockShareCheersActivityTextUseCase extends Mock
    implements ShareCheersActivityTextUseCase {}

class MockPostCheersNoteUseCase extends Mock implements PostCheersNoteUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(ZapGesture.clap);
    registerFallbackValue(createEmptyActivity());
    registerFallbackValue(<String>[]);
  });

  late MockWatchCheersActivitiesUseCase watchCheersActivities;
  late MockSendCheersZapUseCase sendCheersZap;
  late MockSendCheersNudgeUseCase sendCheersNudge;
  late MockLookupLud16UseCase lookupLud16;
  late MockCopyCheersActivityTextUseCase copyText;
  late MockShareCheersActivityTextUseCase shareText;
  late MockPostCheersNoteUseCase postNote;
  late StreamController<List<CheersActivity>> activitiesController;

  setUp(() {
    watchCheersActivities = MockWatchCheersActivitiesUseCase();
    sendCheersZap = MockSendCheersZapUseCase();
    sendCheersNudge = MockSendCheersNudgeUseCase();
    lookupLud16 = MockLookupLud16UseCase();
    copyText = MockCopyCheersActivityTextUseCase();
    shareText = MockShareCheersActivityTextUseCase();
    postNote = MockPostCheersNoteUseCase();
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
      shareText,
      postNote,
      const CheersNoteComposer(),
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

  group('share and copy', () {
    test('copyActivityToClipboard copies the composed note', () async {
      final cubit = createCubit();
      final activity = createEmptyActivity(
        type: CheersActivityType.milestone,
        targetDescription: 'Finished the book',
        isMine: true,
      );
      when(() => copyText(any())).thenAnswer((_) async {});

      await cubit.copyActivityToClipboard(activity);

      final captured =
          verify(() => copyText(captureAny())).captured.single as String;
      expect(captured, contains('#zapbook #reading #nostr'));
      cubit.close();
    });

    test('shareActivity shares the composed note', () async {
      final cubit = createCubit();
      final activity = createEmptyActivity(
        type: CheersActivityType.milestone,
        targetDescription: 'Finished the book',
        isMine: true,
      );
      when(() => shareText(any())).thenAnswer((_) async {});

      await cubit.shareActivity(activity);

      verify(() => shareText(any(that: contains('zapbook.space')))).called(1);
      cubit.close();
    });
  });

  group('postActivityAsNote', () {
    const npub =
        'npub1v4v5td3r04f3n6udfqqv7eulx328y83tndq889yey8n3cnhrntsq8v0wps';

    test('mentions the actor for someone else\'s milestone', () async {
      final cubit = createCubit();
      final activity = createEmptyActivity(
        type: CheersActivityType.milestone,
        actorNpub: npub,
        isMine: false,
      );
      when(
        () => postNote(any(), mentionNpubs: any(named: 'mentionNpubs')),
      ).thenAnswer((_) async {});

      final states = <CheersState>[];
      cubit.stream.listen(states.add);

      await cubit.postActivityAsNote(activity, 'my note text');

      verify(() => postNote('my note text', mentionNpubs: [npub])).called(1);
      await Future.delayed(Duration.zero);
      expect(states.last, isA<CheersPostSuccess>());
      cubit.close();
    });

    test('does not mention anyone for my own milestone', () async {
      final cubit = createCubit();
      final activity = createEmptyActivity(
        type: CheersActivityType.milestone,
        actorNpub: npub,
        isMine: true,
      );
      when(
        () => postNote(any(), mentionNpubs: any(named: 'mentionNpubs')),
      ).thenAnswer((_) async {});

      await cubit.postActivityAsNote(activity, 'my note text');

      verify(
        () => postNote('my note text', mentionNpubs: const <String>[]),
      ).called(1);
      cubit.close();
    });

    test('emits CheersPostError on empty text without posting', () async {
      final cubit = createCubit();
      final activity = createEmptyActivity();

      final states = <CheersState>[];
      cubit.stream.listen(states.add);

      await cubit.postActivityAsNote(activity, '   ');

      await Future.delayed(Duration.zero);
      expect(states.last, isA<CheersPostError>());
      verifyNever(
        () => postNote(any(), mentionNpubs: any(named: 'mentionNpubs')),
      );
      cubit.close();
    });

    test('emits CheersPostError when posting fails', () async {
      final cubit = createCubit();
      final activity = createEmptyActivity(
        type: CheersActivityType.milestone,
        actorNpub: npub,
      );
      when(
        () => postNote(any(), mentionNpubs: any(named: 'mentionNpubs')),
      ).thenThrow(Exception('boom'));

      final states = <CheersState>[];
      cubit.stream.listen(states.add);

      await cubit.postActivityAsNote(activity, 'my note text');

      await Future.delayed(Duration.zero);
      expect(states.last, isA<CheersPostError>());
      cubit.close();
    });
  });
}

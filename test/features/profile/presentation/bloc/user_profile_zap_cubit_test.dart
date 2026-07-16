import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/domain/entities/zap_status.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
import 'package:zapbook/features/profile/domain/usecases/user_profile_usecases.dart';
import 'package:zapbook/features/profile/presentation/bloc/user_profile_zap_cubit.dart';

class MockSendProfileZapUseCase extends Mock implements SendProfileZapUseCase {}

void main() {
  late MockSendProfileZapUseCase sendProfileZap;

  const tProfile = UserProfile(
    npub: 'npub1abc',
    displayName: 'Alice',
    picture: '',
    lightningAddress: 'alice@getalby.com',
    satsEarned: 0,
    dayStreak: 0,
    booksRead: 0,
    milestones: 0,
  );

  setUp(() {
    sendProfileZap = MockSendProfileZapUseCase();
  });

  UserProfileZapCubit buildCubit() => UserProfileZapCubit(sendProfileZap);

  group('UserProfileZapCubit', () {
    blocTest<UserProfileZapCubit, UserProfileZapState>(
      'sendZap emits loading then success',
      build: buildCubit,
      act: (cubit) async {
        when(
          () => sendProfileZap(
            profile: tProfile,
            gesture: ZapGesture.fire,
            customSats: null,
            comment: null,
          ),
        ).thenAnswer((_) async {});
        await cubit.sendZap(profile: tProfile, gesture: ZapGesture.fire);
      },
      expect: () => [
        const UserProfileZapLoading(ZapGesture.fire),
        const UserProfileZapSuccess(amountSats: 1000, profileLabel: 'Alice'),
      ],
    );

    blocTest<UserProfileZapCubit, UserProfileZapState>(
      'sendZap emits failure with ZapException message',
      build: buildCubit,
      act: (cubit) async {
        when(
          () => sendProfileZap(
            profile: tProfile,
            gesture: ZapGesture.fire,
            customSats: null,
            comment: null,
          ),
        ).thenThrow(const ZapException('No lightning address'));
        await cubit.sendZap(profile: tProfile, gesture: ZapGesture.fire);
      },
      expect: () => [
        const UserProfileZapLoading(ZapGesture.fire),
        const UserProfileZapFailure('No lightning address'),
      ],
    );

    blocTest<UserProfileZapCubit, UserProfileZapState>(
      'sendZap emits fallback failure for unexpected error',
      build: buildCubit,
      act: (cubit) async {
        when(
          () => sendProfileZap(
            profile: tProfile,
            gesture: ZapGesture.fire,
            customSats: null,
            comment: null,
          ),
        ).thenThrow(StateError('boom'));
        await cubit.sendZap(profile: tProfile, gesture: ZapGesture.fire);
      },
      expect: () => [
        const UserProfileZapLoading(ZapGesture.fire),
        const UserProfileZapFailure('Could not zap Alice'),
      ],
    );

    blocTest<UserProfileZapCubit, UserProfileZapState>(
      'sendZap uses customSats for gift gesture amount',
      build: buildCubit,
      act: (cubit) async {
        when(
          () => sendProfileZap(
            profile: tProfile,
            gesture: ZapGesture.gift,
            customSats: 250,
            comment: 'nice',
          ),
        ).thenAnswer((_) async {});
        await cubit.sendZap(
          profile: tProfile,
          gesture: ZapGesture.gift,
          customSats: 250,
          comment: 'nice',
        );
      },
      expect: () => [
        const UserProfileZapLoading(ZapGesture.gift),
        const UserProfileZapSuccess(amountSats: 250, profileLabel: 'Alice'),
      ],
    );
  });
}

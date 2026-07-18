import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/domain/usecases/clipboard_usecases.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
import 'package:zapbook/features/profile/domain/usecases/user_profile_usecases.dart';
import 'package:zapbook/features/profile/presentation/bloc/user_profile_cubit.dart';

class MockLoadUserProfileUseCase extends Mock
    implements LoadUserProfileUseCase {}

class MockToggleFollowUseCase extends Mock implements ToggleFollowUseCase {}

class MockCopyTextUseCase extends Mock implements CopyTextUseCase {}

void main() {
  late MockLoadUserProfileUseCase loadUserProfile;
  late MockToggleFollowUseCase toggleFollow;
  late MockCopyTextUseCase copyText;

  const tProfile = UserProfile(
    npub: 'npub1abc',
    displayName: 'Alice',
    picture: '',
    lightningAddress: '',
    satsEarned: 0,
    dayStreak: 3,
    booksRead: 2,
    milestones: 1,
  );

  setUp(() {
    loadUserProfile = MockLoadUserProfileUseCase();
    toggleFollow = MockToggleFollowUseCase();
    copyText = MockCopyTextUseCase();
  });

  UserProfileCubit buildCubit() =>
      UserProfileCubit(loadUserProfile, toggleFollow, copyText);

  group('UserProfileCubit', () {
    blocTest<UserProfileCubit, UserProfileState>(
      'load emits loading then loaded on success',
      build: buildCubit,
      act: (cubit) async {
        when(
          () => loadUserProfile('npub1abc'),
        ).thenAnswer((_) async => tProfile);
        await cubit.load('npub1abc');
      },
      expect: () => [
        const UserProfileLoading(),
        const UserProfileLoaded(tProfile),
      ],
    );

    blocTest<UserProfileCubit, UserProfileState>(
      'load emits loading then error on failure',
      build: buildCubit,
      act: (cubit) async {
        when(() => loadUserProfile('npub1abc')).thenThrow(Exception('boom'));
        await cubit.load('npub1abc');
      },
      expect: () => [
        const UserProfileLoading(),
        const UserProfileError('Could not load profile'),
      ],
    );

    blocTest<UserProfileCubit, UserProfileState>(
      'toggleFollow flips isFollow optimistically and calls usecase',
      build: buildCubit,
      seed: () => const UserProfileLoaded(tProfile),
      act: (cubit) async {
        when(() => toggleFollow('npub1abc', false)).thenAnswer((_) async {});
        await cubit.toggleFollow();
      },
      expect: () => [UserProfileLoaded(tProfile.copyWith(isFollow: true))],
      verify: (_) {
        verify(() => toggleFollow('npub1abc', false)).called(1);
      },
    );

    blocTest<UserProfileCubit, UserProfileState>(
      'toggleFollow reverts state when usecase throws',
      build: buildCubit,
      seed: () => const UserProfileLoaded(tProfile),
      act: (cubit) async {
        when(
          () => toggleFollow('npub1abc', false),
        ).thenThrow(Exception('offline'));
        await cubit.toggleFollow();
      },
      expect: () => [
        UserProfileLoaded(tProfile.copyWith(isFollow: true)),
        const UserProfileLoaded(tProfile),
      ],
    );

    blocTest<UserProfileCubit, UserProfileState>(
      'toggleFollow does nothing when profile not loaded',
      build: buildCubit,
      act: (cubit) => cubit.toggleFollow(),
      expect: () => <UserProfileState>[],
      verify: (_) {
        verifyNever(() => toggleFollow(any(), any()));
      },
    );

    test('copy delegates to CopyTextUseCase', () async {
      when(() => copyText('npub1abc')).thenAnswer((_) async {});
      final cubit = buildCubit();
      await cubit.copy('npub1abc');
      verify(() => copyText('npub1abc')).called(1);
    });
  });
}

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/features/profile/domain/usecases/friends_usecases.dart';
import 'package:zapbook/features/profile/presentation/bloc/friends_cubit.dart';
import 'package:zapbook/features/profile/presentation/bloc/friends_state.dart';

class MockFriendsUseCases extends Mock implements FriendsUseCases {}

void main() {
  late MockFriendsUseCases usecases;
  late StreamController<List<Contact>> friendsController;

  setUp(() {
    usecases = MockFriendsUseCases();
    friendsController = StreamController<List<Contact>>.broadcast();

    when(() => usecases.friends).thenAnswer((_) => friendsController.stream);
  });

  tearDown(() {
    friendsController.close();
  });

  FriendsCubit buildCubit() => FriendsCubit(usecases);

  group('FriendsCubit', () {
    test('initial state is FriendsLoading', () {
      final cubit = buildCubit();
      expect(cubit.state, const FriendsLoading());
    });

    blocTest<FriendsCubit, FriendsState>(
      'load subscribes to friends stream',
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        friendsController.add([
          const Contact(npub: 'npub1', displayName: 'Alice'),
        ]);
      },
      expect: () => [
        const FriendsLoaded([Contact(npub: 'npub1', displayName: 'Alice')]),
      ],
    );

    blocTest<FriendsCubit, FriendsState>(
      'load emits error when stream emits error',
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        friendsController.addError(Exception('stream fail'));
      },
      expect: () => [
        const FriendsError(friends: [], message: 'Failed to load friends'),
      ],
    );

    blocTest<FriendsCubit, FriendsState>(
      'addNpub validates and emits error for invalid npub',
      build: buildCubit,
      act: (cubit) async {
        when(() => usecases.isValidNpub('bad')).thenReturn(false);
        await cubit.addNpub('bad');
      },
      expect: () => [
        const FriendsError(friends: [], message: 'Not a valid npub'),
      ],
    );

    blocTest<FriendsCubit, FriendsState>(
      'addNpub success',
      build: buildCubit,
      act: (cubit) async {
        when(() => usecases.isValidNpub('npub1')).thenReturn(true);
        when(() => usecases.add('npub1')).thenAnswer((_) async {});
        await cubit.addNpub('npub1');
      },
      expect: () => [
        const FriendsBusy(friends: [], busyNpub: 'npub1', adding: true),
      ],
      verify: (_) {
        verify(() => usecases.add('npub1')).called(1);
      },
    );

    blocTest<FriendsCubit, FriendsState>(
      'addNpub handles ContactException',
      build: buildCubit,
      act: (cubit) async {
        when(() => usecases.isValidNpub('npub1')).thenReturn(true);
        when(
          () => usecases.add('npub1'),
        ).thenThrow(const ContactException('Already a friend'));
        await cubit.addNpub('npub1');
      },
      expect: () => [
        const FriendsBusy(friends: [], busyNpub: 'npub1', adding: true),
        const FriendsError(friends: [], message: 'Already a friend'),
      ],
    );

    blocTest<FriendsCubit, FriendsState>(
      'remove success',
      build: buildCubit,
      seed: () =>
          const FriendsLoaded([Contact(npub: 'npub1', displayName: 'A')]),
      act: (cubit) async {
        when(() => usecases.remove('npub1')).thenAnswer((_) async {});
        await cubit.remove('npub1');
      },
      expect: () => [
        const FriendsBusy(
          friends: [Contact(npub: 'npub1', displayName: 'A')],
          busyNpub: 'npub1',
        ),
      ],
      verify: (_) {
        verify(() => usecases.remove('npub1')).called(1);
      },
    );

    blocTest<FriendsCubit, FriendsState>(
      'remove handles general exception',
      build: buildCubit,
      seed: () =>
          const FriendsLoaded([Contact(npub: 'npub1', displayName: 'A')]),
      act: (cubit) async {
        when(() => usecases.remove('npub1')).thenThrow(Exception('Fail'));
        await cubit.remove('npub1');
      },
      expect: () => [
        const FriendsBusy(
          friends: [Contact(npub: 'npub1', displayName: 'A')],
          busyNpub: 'npub1',
        ),
        const FriendsLoaded([Contact(npub: 'npub1', displayName: 'A')]),
      ],
    );

    test('resolveNpub calls contact service', () async {
      when(
        () => usecases.resolve('npub1'),
      ).thenAnswer((_) async => const Contact(npub: 'npub1', displayName: 'A'));

      final cubit = buildCubit();
      final c = await cubit.resolveNpub('npub1');
      expect(c.displayName, 'A');
    });

    test('contactCount returns length', () {
      final cubit = buildCubit();
      cubit.emit(
        const FriendsLoaded([Contact(npub: 'npub1', displayName: 'A')]),
      );
      expect(cubit.contactCount, 1);
    });
  });
}

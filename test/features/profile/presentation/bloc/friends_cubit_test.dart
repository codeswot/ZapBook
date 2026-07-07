import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/features/profile/presentation/bloc/friends_cubit.dart';
import 'package:zapbook/features/profile/presentation/bloc/friends_state.dart';

class MockContactService extends Mock implements ContactService {}

void main() {
  late MockContactService contactService;
  late StreamController<List<Contact>> friendsStreamController;

  const tContact = Contact(npub: 'npub', displayName: 'Test', picture: '');

  setUp(() {
    contactService = MockContactService();
    friendsStreamController = StreamController<List<Contact>>();

    when(
      () => contactService.friends,
    ).thenAnswer((_) => friendsStreamController.stream);
    when(() => contactService.isValidNpub('npub')).thenReturn(true);
    when(() => contactService.isValidNpub('invalid')).thenReturn(false);
  });

  tearDown(() {
    friendsStreamController.close();
  });

  FriendsCubit buildCubit() => FriendsCubit(contactService);

  group('FriendsCubit', () {
    test('initial state is FriendsLoading', () {
      final cubit = buildCubit();
      expect(cubit.state, const FriendsLoading());
    });

    blocTest<FriendsCubit, FriendsState>(
      'load emits FriendsLoaded when stream emits',
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        friendsStreamController.add([tContact]);
      },
      expect: () => [
        const FriendsLoaded([tContact]),
      ],
    );

    blocTest<FriendsCubit, FriendsState>(
      'load emits FriendsError when stream errors',
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        friendsStreamController.addError(Exception('stream error'));
      },
      expect: () => [
        const FriendsError(message: 'Failed to load friends', friends: []),
      ],
    );

    blocTest<FriendsCubit, FriendsState>(
      'load emits FriendsError when stream done',
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        await friendsStreamController.close();
      },
      expect: () => [
        const FriendsError(message: 'Friends stream closed', friends: []),
      ],
    );

    blocTest<FriendsCubit, FriendsState>(
      'addNpub emits nothing if npub is empty',
      build: buildCubit,
      act: (cubit) async => cubit.addNpub(''),
      expect: () => [],
    );

    blocTest<FriendsCubit, FriendsState>(
      'addNpub emits Error if npub is invalid',
      build: buildCubit,
      act: (cubit) async => cubit.addNpub('invalid'),
      expect: () => [
        const FriendsError(message: 'Not a valid npub', friends: []),
      ],
    );

    blocTest<FriendsCubit, FriendsState>(
      'addNpub emits Busy and adds contact',
      build: buildCubit,
      act: (cubit) async {
        when(
          () => contactService.add('npub'),
        ).thenAnswer((_) async => tContact);
        await cubit.addNpub('npub');
      },
      expect: () => [
        const FriendsBusy(friends: [], busyNpub: 'npub', adding: true),
      ],
      verify: (_) {
        verify(() => contactService.add('npub')).called(1);
      },
    );

    blocTest<FriendsCubit, FriendsState>(
      'addNpub emits Error on ContactException',
      build: buildCubit,
      act: (cubit) async {
        when(
          () => contactService.add('npub'),
        ).thenThrow(ContactException('Already a friend'));
        await cubit.addNpub('npub');
      },
      expect: () => [
        const FriendsBusy(friends: [], busyNpub: 'npub', adding: true),
        const FriendsError(message: 'Already a friend', friends: []),
      ],
    );

    blocTest<FriendsCubit, FriendsState>(
      'addNpub emits Error on general Exception',
      build: buildCubit,
      act: (cubit) async {
        when(() => contactService.add('npub')).thenThrow(Exception('Fail'));
        await cubit.addNpub('npub');
      },
      expect: () => [
        const FriendsBusy(friends: [], busyNpub: 'npub', adding: true),
        const FriendsError(message: 'Could not add contact', friends: []),
      ],
    );

    blocTest<FriendsCubit, FriendsState>(
      'remove emits Busy and removes contact',
      build: buildCubit,
      seed: () => const FriendsLoaded([tContact]),
      act: (cubit) async {
        when(() => contactService.remove('npub')).thenAnswer((_) async {});
        await cubit.remove('npub');
      },
      expect: () => [
        const FriendsBusy(friends: [tContact], busyNpub: 'npub'),
      ],
      verify: (_) {
        verify(() => contactService.remove('npub')).called(1);
      },
    );

    blocTest<FriendsCubit, FriendsState>(
      'remove emits Loaded on failure',
      build: buildCubit,
      seed: () => const FriendsLoaded([tContact]),
      act: (cubit) async {
        when(() => contactService.remove('npub')).thenThrow(Exception('Fail'));
        await cubit.remove('npub');
      },
      expect: () => [
        const FriendsBusy(friends: [tContact], busyNpub: 'npub'),
        const FriendsLoaded([tContact]),
      ],
    );

    test('resolveNpub calls service', () async {
      when(
        () => contactService.resolve('npub'),
      ).thenAnswer((_) async => tContact);
      final cubit = buildCubit();
      final res = await cubit.resolveNpub('npub');
      expect(res, tContact);
      verify(() => contactService.resolve('npub')).called(1);
    });

    test('contactCount returns length', () async {
      final cubit = buildCubit();
      expect(cubit.contactCount, 0);

      cubit.emit(const FriendsLoaded([tContact]));
      expect(cubit.contactCount, 1);
    });
  });
}

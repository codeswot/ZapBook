import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/features/circles/presentation/bloc/circle_detail_cubit.dart';
import 'package:zapbook/features/circles/domain/usecases/circles_usecases.dart';

import 'package:zapbook/features/circles/presentation/bloc/circle_detail_state.dart';
import 'package:zapbook/zbf/enums/book_source_format.dart';

class MockGetCircleBookUseCase extends Mock implements GetCircleBookUseCase {}

class MockGetMyNpubUseCase extends Mock implements GetMyNpubUseCase {}

class MockGetCircleMembersUseCase extends Mock
    implements GetCircleMembersUseCase {}

class MockWatchProgressByBookUseCase extends Mock
    implements WatchProgressByBookUseCase {}

class MockRemoveCircleMemberUseCase extends Mock
    implements RemoveCircleMemberUseCase {}

class MockToggleContactUseCase extends Mock implements ToggleContactUseCase {}

class MockLeaveCircleBookUseCase extends Mock
    implements LeaveCircleBookUseCase {}

class MockDeleteCircleBookUseCase extends Mock
    implements DeleteCircleBookUseCase {}

CircleBook _createTestBook(String id, String title, List<String> adminNpubs) {
  return CircleBook(
    id: id,
    nostrGroudId: 'g_$id',
    circleDirId: 'dir_$id',
    title: title,
    author: 'Author',
    sourceFormat: BookSourceFormat.epub,
    pageCount: 1,
    chapterCount: 1,
    zbfPath: '/path',
    needsAiProcessing: false,
    zbfVersion: '1.0',
    createdAt: DateTime.now(),
    addedAt: DateTime.now(),
    adminNpubs: adminNpubs,
  );
}

void main() {
  late MockGetCircleBookUseCase mockGetCircleBookUseCase;
  late MockGetMyNpubUseCase mockGetMyNpubUseCase;
  late MockGetCircleMembersUseCase mockGetCircleMembersUseCase;
  late MockWatchProgressByBookUseCase mockWatchProgressByBookUseCase;
  late MockRemoveCircleMemberUseCase mockRemoveCircleMemberUseCase;
  late MockToggleContactUseCase mockToggleContactUseCase;
  late MockLeaveCircleBookUseCase mockLeaveCircleBookUseCase;
  late MockDeleteCircleBookUseCase mockDeleteCircleBookUseCase;

  final testBook = _createTestBook('book1', 'Test Book', ['npub1admin']);

  setUp(() {
    mockGetCircleBookUseCase = MockGetCircleBookUseCase();
    mockGetMyNpubUseCase = MockGetMyNpubUseCase();
    mockGetCircleMembersUseCase = MockGetCircleMembersUseCase();
    mockWatchProgressByBookUseCase = MockWatchProgressByBookUseCase();
    mockRemoveCircleMemberUseCase = MockRemoveCircleMemberUseCase();
    mockToggleContactUseCase = MockToggleContactUseCase();
    mockLeaveCircleBookUseCase = MockLeaveCircleBookUseCase();
    mockDeleteCircleBookUseCase = MockDeleteCircleBookUseCase();

    when(
      () => mockWatchProgressByBookUseCase(
        groupId: any(named: 'groupId'),
        bookId: any(named: 'bookId'),
      ),
    ).thenAnswer((_) => Stream.value([]));
  });

  CircleDetailCubit buildCubit() => CircleDetailCubit(
    mockGetCircleBookUseCase,
    mockGetMyNpubUseCase,
    mockGetCircleMembersUseCase,
    mockWatchProgressByBookUseCase,
    mockRemoveCircleMemberUseCase,
    mockToggleContactUseCase,
    mockLeaveCircleBookUseCase,
    mockDeleteCircleBookUseCase,
  );

  group('CircleDetailCubit', () {
    test('load emits error if book not found', () async {
      when(
        () => mockGetCircleBookUseCase('book1'),
      ).thenAnswer((_) async => null);
      final cubit = buildCubit();

      await cubit.load('book1');

      expect(cubit.state, isA<CircleDetailError>());
      expect((cubit.state as CircleDetailError).message, 'Circle not found');
    });

    test('load emits loaded state with members', () async {
      when(
        () => mockGetCircleBookUseCase('book1'),
      ).thenAnswer((_) async => testBook);
      when(() => mockGetMyNpubUseCase()).thenAnswer((_) async => 'npub1me');
      when(() => mockGetCircleMembersUseCase('book1')).thenAnswer(
        (_) async => [
          const Contact(npub: 'npub1me', displayName: 'Me', isFollow: true),
          const Contact(
            npub: 'npub1other',
            displayName: 'Other',
            isFollow: false,
          ),
        ],
      );

      final cubit = buildCubit();
      await cubit.load('book1');

      expect(cubit.state, isA<CircleDetailLoaded>());
      final state = cubit.state as CircleDetailLoaded;
      expect(state.book, testBook);
      expect(state.myNpub, 'npub1me');
      expect(state.members.length, 2);
      expect(state.members.last.npub, 'npub1me');
      expect(state.members.last.isSelf, true);
      expect(state.members.last.isFollow, true);
      expect(state.members.first.npub, 'npub1other');
      expect(state.members.first.isSelf, false);
      expect(state.members.first.isFollow, false);
    });

    test('removeMember removes and refreshes', () async {
      when(
        () => mockGetCircleBookUseCase('book1'),
      ).thenAnswer((_) async => testBook);
      when(() => mockGetMyNpubUseCase()).thenAnswer((_) async => 'npub1me');
      when(
        () => mockGetCircleMembersUseCase('book1'),
      ).thenAnswer((_) async => []);

      when(
        () => mockRemoveCircleMemberUseCase('book1', 'npub1other'),
      ).thenAnswer((_) async {});

      final cubit = buildCubit();
      await cubit.load('book1');

      await cubit.removeMember('book1', 'npub1other');

      verify(
        () => mockRemoveCircleMemberUseCase('book1', 'npub1other'),
      ).called(1);
      // It refreshes by calling getCircleMembers again
      verify(() => mockGetCircleMembersUseCase('book1')).called(2);
    });

    test('toggleContact toggles follow state and refreshes', () async {
      when(
        () => mockGetCircleBookUseCase('book1'),
      ).thenAnswer((_) async => testBook);
      when(() => mockGetMyNpubUseCase()).thenAnswer((_) async => 'npub1me');
      when(
        () => mockGetCircleMembersUseCase('book1'),
      ).thenAnswer((_) async => []);

      when(
        () => mockToggleContactUseCase('npub1other', any()),
      ).thenAnswer((_) async {});

      final cubit = buildCubit();
      await cubit.load('book1');

      await cubit.toggleContact('npub1other', false);
      verify(() => mockToggleContactUseCase('npub1other', false)).called(1);
      verify(() => mockGetCircleMembersUseCase('book1')).called(2);

      await cubit.toggleContact('npub1other', true);
      verify(() => mockToggleContactUseCase('npub1other', true)).called(1);
      verify(() => mockGetCircleMembersUseCase('book1')).called(1);
    });

    test('leaveAndDelete leaves and deletes book, emits closed', () async {
      when(
        () => mockGetCircleBookUseCase('book1'),
      ).thenAnswer((_) async => testBook);
      when(() => mockGetMyNpubUseCase()).thenAnswer((_) async => 'npub1me');
      when(
        () => mockGetCircleMembersUseCase('book1'),
      ).thenAnswer((_) async => []);

      when(() => mockLeaveCircleBookUseCase(testBook)).thenAnswer((_) async {});
      when(
        () => mockDeleteCircleBookUseCase(testBook),
      ).thenAnswer((_) async {});

      final cubit = buildCubit();
      await cubit.load('book1');

      await cubit.leaveAndDelete(testBook);

      expect(cubit.state, isA<CircleDetailClosed>());
      verify(() => mockLeaveCircleBookUseCase(testBook)).called(1);
      verify(() => mockDeleteCircleBookUseCase(testBook)).called(1);
    });

    test('dissolve deletes book and emits closed', () async {
      when(
        () => mockGetCircleBookUseCase('book1'),
      ).thenAnswer((_) async => testBook);
      when(() => mockGetMyNpubUseCase()).thenAnswer((_) async => 'npub1me');
      when(
        () => mockGetCircleMembersUseCase('book1'),
      ).thenAnswer((_) async => []);

      when(
        () => mockDeleteCircleBookUseCase(testBook),
      ).thenAnswer((_) async {});

      final cubit = buildCubit();
      await cubit.load('book1');

      await cubit.dissolve(testBook);

      expect(cubit.state, isA<CircleDetailClosed>());
      verifyNever(() => mockLeaveCircleBookUseCase(testBook));
      verify(() => mockDeleteCircleBookUseCase(testBook)).called(1);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/circle_store_service.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/features/circles/presentation/bloc/circle_detail_cubit.dart';
import 'package:zapbook/core/data/dao/circle_progress_dao.dart';

import 'package:zapbook/features/circles/presentation/bloc/circle_detail_state.dart';
import 'package:zapbook/zbf/enums/book_source_format.dart';

class MockIdentityLocalDataSource extends Mock
    implements IdentityLocalDataSource {}

class MockCircleStoreService extends Mock implements CircleStoreService {}

class MockContactService extends Mock implements ContactService {}

class MockCircleProgressDao extends Mock implements CircleProgressDao {}

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
  late MockIdentityLocalDataSource mockIdentity;
  late MockCircleStoreService mockCircleStore;
  late MockContactService mockContacts;
  late MockCircleProgressDao mockCircleProgressDao;

  final testBook = _createTestBook('book1', 'Test Book', ['npub1admin']);

  setUp(() {
    mockIdentity = MockIdentityLocalDataSource();
    mockCircleStore = MockCircleStoreService();
    mockContacts = MockContactService();
    mockCircleProgressDao = MockCircleProgressDao();
    when(
      () => mockCircleProgressDao.watchProgressByBook(
        groupId: any(named: 'groupId'),
        bookId: any(named: 'bookId'),
      ),
    ).thenAnswer((_) => Stream.value([]));
  });

  CircleDetailCubit buildCubit() => CircleDetailCubit(
    mockIdentity,
    mockCircleStore,
    mockContacts,
    mockCircleProgressDao,
  );

  group('CircleDetailCubit', () {
    test('load emits error if book not found', () async {
      when(() => mockCircleStore.currentCircles).thenReturn([]);
      final cubit = buildCubit();

      await cubit.load('book1');

      expect(cubit.state, isA<CircleDetailError>());
      expect((cubit.state as CircleDetailError).message, 'Circle not found');
    });

    test('load emits loaded state with members', () async {
      when(() => mockCircleStore.currentCircles).thenReturn([testBook]);
      when(() => mockIdentity.readNpub()).thenAnswer((_) async => 'npub1me');
      when(() => mockCircleStore.getCircleMembers('book1')).thenAnswer(
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
      when(() => mockCircleStore.currentCircles).thenReturn([testBook]);
      when(() => mockIdentity.readNpub()).thenAnswer((_) async => 'npub1me');
      when(
        () => mockCircleStore.getCircleMembers('book1'),
      ).thenAnswer((_) async => []);

      when(
        () => mockCircleStore.removeCircleMember('book1', 'npub1other'),
      ).thenAnswer((_) async {});

      final cubit = buildCubit();
      await cubit.load('book1');

      await cubit.removeMember('book1', 'npub1other');

      verify(
        () => mockCircleStore.removeCircleMember('book1', 'npub1other'),
      ).called(1);
      // It refreshes by calling getCircleMembers again
      verify(() => mockCircleStore.getCircleMembers('book1')).called(2);
    });

    test('toggleContact toggles follow state and refreshes', () async {
      when(() => mockCircleStore.currentCircles).thenReturn([testBook]);
      when(() => mockIdentity.readNpub()).thenAnswer((_) async => 'npub1me');
      when(
        () => mockCircleStore.getCircleMembers('book1'),
      ).thenAnswer((_) async => []);

      when(
        () => mockContacts.add('npub1other'),
      ).thenAnswer((_) async => const Contact(npub: 'npub1other'));
      when(() => mockContacts.remove('npub1other')).thenAnswer((_) async {});

      final cubit = buildCubit();
      await cubit.load('book1');

      await cubit.toggleContact('npub1other', false);
      verify(() => mockContacts.add('npub1other')).called(1);
      verify(() => mockCircleStore.getCircleMembers('book1')).called(2);

      await cubit.toggleContact('npub1other', true);
      verify(() => mockContacts.remove('npub1other')).called(1);
      verify(() => mockCircleStore.getCircleMembers('book1')).called(1);
    });

    test('leaveAndDelete leaves and deletes book, emits closed', () async {
      when(() => mockCircleStore.currentCircles).thenReturn([testBook]);
      when(() => mockIdentity.readNpub()).thenAnswer((_) async => 'npub1me');
      when(
        () => mockCircleStore.getCircleMembers('book1'),
      ).thenAnswer((_) async => []);

      when(
        () => mockCircleStore.leaveCircleBook(testBook),
      ).thenAnswer((_) async {});
      when(
        () => mockCircleStore.deleteCircleBook(testBook),
      ).thenAnswer((_) async {});

      final cubit = buildCubit();
      await cubit.load('book1');

      await cubit.leaveAndDelete(testBook);

      expect(cubit.state, isA<CircleDetailClosed>());
      verify(() => mockCircleStore.leaveCircleBook(testBook)).called(1);
      verify(() => mockCircleStore.deleteCircleBook(testBook)).called(1);
    });

    test('dissolve deletes book and emits closed', () async {
      when(() => mockCircleStore.currentCircles).thenReturn([testBook]);
      when(() => mockIdentity.readNpub()).thenAnswer((_) async => 'npub1me');
      when(
        () => mockCircleStore.getCircleMembers('book1'),
      ).thenAnswer((_) async => []);

      when(
        () => mockCircleStore.deleteCircleBook(testBook),
      ).thenAnswer((_) async {});

      final cubit = buildCubit();
      await cubit.load('book1');

      await cubit.dissolve(testBook);

      expect(cubit.state, isA<CircleDetailClosed>());
      verifyNever(() => mockCircleStore.leaveCircleBook(testBook));
      verify(() => mockCircleStore.deleteCircleBook(testBook)).called(1);
    });
  });
}

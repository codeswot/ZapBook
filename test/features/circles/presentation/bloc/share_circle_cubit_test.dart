import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/features/circles/domain/usecases/circles_usecases.dart';
import 'package:zapbook/features/circles/presentation/bloc/share_circle_cubit.dart';
import 'package:zapbook/features/circles/presentation/bloc/share_circle_state.dart';
import 'package:zapbook/features/circles/domain/entities/share_skip.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/zbf/enums/book_source_format.dart';

class MockGetFriendsUseCase extends Mock implements GetFriendsUseCase {}

class MockGetCircleBookUseCase extends Mock implements GetCircleBookUseCase {}

class MockGetExistingMemberNpubsUseCase extends Mock
    implements GetExistingMemberNpubsUseCase {}

class MockShareCircleBookUseCase extends Mock
    implements ShareCircleBookUseCase {}

class MockGetMyNpubUseCase extends Mock implements GetMyNpubUseCase {}

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
  late MockGetFriendsUseCase mockGetFriendsUseCase;
  late MockGetCircleBookUseCase mockGetCircleBookUseCase;
  late MockGetExistingMemberNpubsUseCase mockGetExistingMemberNpubsUseCase;
  late MockShareCircleBookUseCase mockShareCircleBookUseCase;
  late MockGetMyNpubUseCase mockGetMyNpubUseCase;

  setUp(() {
    mockGetFriendsUseCase = MockGetFriendsUseCase();
    mockGetCircleBookUseCase = MockGetCircleBookUseCase();
    mockGetExistingMemberNpubsUseCase = MockGetExistingMemberNpubsUseCase();
    mockShareCircleBookUseCase = MockShareCircleBookUseCase();
    mockGetMyNpubUseCase = MockGetMyNpubUseCase();
  });

  ShareCircleCubit buildCubit() => ShareCircleCubit(
    mockGetFriendsUseCase,
    mockGetCircleBookUseCase,
    mockGetExistingMemberNpubsUseCase,
    mockShareCircleBookUseCase,
    mockGetMyNpubUseCase,
  );

  group('ShareCircleCubit', () {
    test('isValidNpub correctly validates npub strings', () {
      final cubit = buildCubit();

      expect(cubit.isValidNpub(''), false);
      expect(cubit.isValidNpub('invalid_npub'), false);
      expect(
        cubit.isValidNpub(
          'npub1v4v5td3r04f3n6udfqqv7eulx328y83tndq889yey8n3cnhrntsq8v0wps',
        ),
        true,
      );
    });

    test('load fetches friends and existing members', () async {
      final friendsList = [
        const Contact(npub: 'npub11', displayName: 'Friend 1'),
      ];
      final testBook = _createTestBook('book1', 'Test', []);

      when(() => mockGetFriendsUseCase()).thenAnswer((_) async => friendsList);
      when(
        () => mockGetCircleBookUseCase('book1'),
      ).thenAnswer((_) async => testBook);
      when(
        () => mockGetExistingMemberNpubsUseCase('book1'),
      ).thenAnswer((_) async => {'npub12'});

      final cubit = buildCubit();
      await cubit.load('book1');

      expect(cubit.state, isA<ShareCircleLoaded>());
      final state = cubit.state as ShareCircleLoaded;
      expect(state.friends, friendsList);
      expect(state.existingMembers, {'npub12'});
      expect(state.selectedNpubs, isEmpty);
    });

    test('toggleNpub toggles selection', () async {
      when(() => mockGetFriendsUseCase()).thenAnswer((_) async => []);
      when(
        () => mockGetCircleBookUseCase('book1'),
      ).thenAnswer((_) async => null);
      when(
        () => mockGetExistingMemberNpubsUseCase('book1'),
      ).thenAnswer((_) async => {});

      final cubit = buildCubit();
      await cubit.load('book1');

      cubit.toggleNpub('npub1');
      var state = cubit.state as ShareCircleLoaded;
      expect(state.selectedNpubs, ['npub1']);

      cubit.toggleNpub('npub1');
      state = cubit.state as ShareCircleLoaded;
      expect(state.selectedNpubs, isEmpty);
    });

    test('addNpub adds to selection and emits loaded', () async {
      when(() => mockGetFriendsUseCase()).thenAnswer((_) async => []);
      when(
        () => mockGetCircleBookUseCase('book1'),
      ).thenAnswer((_) async => null);
      when(
        () => mockGetExistingMemberNpubsUseCase('book1'),
      ).thenAnswer((_) async => {});

      final cubit = buildCubit();
      await cubit.load('book1');

      await cubit.addNpub(
        'npub1v4v5td3r04f3n6udfqqv7eulx328y83tndq889yey8n3cnhrntsq8v0wps',
      );

      expect(cubit.state, isA<ShareCircleLoaded>());
      expect((cubit.state as ShareCircleLoaded).selectedNpubs, [
        'npub1v4v5td3r04f3n6udfqqv7eulx328y83tndq889yey8n3cnhrntsq8v0wps',
      ]);
    });

    test('share returns empty if no selection', () async {
      when(() => mockGetFriendsUseCase()).thenAnswer((_) async => []);
      when(
        () => mockGetCircleBookUseCase('book1'),
      ).thenAnswer((_) async => null);
      when(
        () => mockGetExistingMemberNpubsUseCase('book1'),
      ).thenAnswer((_) async => {});

      final cubit = buildCubit();
      await cubit.load('book1');

      final result = await cubit.share('book1');
      expect(result, isEmpty);
    });

    test('share calls share service and returns skips', () async {
      when(() => mockGetFriendsUseCase()).thenAnswer((_) async => []);
      when(
        () => mockGetCircleBookUseCase('book1'),
      ).thenAnswer((_) async => null);
      when(
        () => mockGetExistingMemberNpubsUseCase('book1'),
      ).thenAnswer((_) async => {});
      when(() => mockGetMyNpubUseCase()).thenAnswer((_) async => 'npubMy');

      final skipsResult = [
        const ShareSkip(npub: 'npub2', reason: ShareSkipReason.unknownError),
      ];
      when(
        () => mockShareCircleBookUseCase(
          circleBookId: 'book1',
          npubs: ['npub1', 'npub2'],
          myNpub: 'npubMy',
        ),
      ).thenAnswer((_) async => skipsResult);

      final cubit = buildCubit();
      await cubit.load('book1');

      await cubit.addNpub('npub1');
      await cubit.addNpub('npub2');

      final result = await cubit.share('book1');

      expect(result, skipsResult);

      verify(
        () => mockShareCircleBookUseCase(
          circleBookId: 'book1',
          npubs: ['npub1', 'npub2'],
          myNpub: 'npubMy',
        ),
      ).called(1);

      final finalState = cubit.state as ShareCircleLoaded;
      expect(finalState.selectedNpubs, isEmpty);
      expect(finalState.shareResult, skipsResult);
    });

    test('share rethrows on error', () async {
      when(() => mockGetFriendsUseCase()).thenAnswer((_) async => []);
      when(
        () => mockGetCircleBookUseCase('book1'),
      ).thenAnswer((_) async => null);
      when(
        () => mockGetExistingMemberNpubsUseCase('book1'),
      ).thenAnswer((_) async => {});
      when(() => mockGetMyNpubUseCase()).thenAnswer((_) async => 'npubMy');

      when(
        () => mockShareCircleBookUseCase(
          circleBookId: 'book1',
          npubs: ['npub1'],
          myNpub: 'npubMy',
        ),
      ).thenThrow(Exception('test error'));

      final cubit = buildCubit();
      await cubit.load('book1');
      await cubit.addNpub('npub1');

      await expectLater(() => cubit.share('book1'), throwsException);

      final finalState = cubit.state as ShareCircleLoaded;
      expect(finalState.selectedNpubs, ['npub1']);
    });
  });
}

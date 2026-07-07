import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:zapbook/core/identity/active_account.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/core/services/circle_store_service.dart';
import 'package:zapbook/features/circles/domain/entities/share_skip.dart';
import 'package:zapbook/features/circles/domain/usecases/share_circle_book.dart';
import 'package:zapbook/features/circles/presentation/bloc/share_circle_cubit.dart';
import 'package:zapbook/features/circles/presentation/bloc/share_circle_state.dart';
import 'package:zapbook/zbf/enums/book_source_format.dart';

class MockContactService extends Mock implements ContactService {}

class MockCircleStoreService extends Mock implements CircleStoreService {}

class MockMarmot extends Mock implements Marmot {}

class MockShareCircleBookUseCase extends Mock
    implements ShareCircleBookUseCase {}

CircleBook _createTestBook(String id, String title) {
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
  );
}

void main() {
  late MockContactService mockContactService;
  late MockCircleStoreService mockCircleStore;
  late MockMarmot mockMarmot;
  late MockShareCircleBookUseCase mockShareUseCase;

  setUp(() {
    mockContactService = MockContactService();
    mockCircleStore = MockCircleStoreService();
    mockMarmot = MockMarmot();
    mockShareUseCase = MockShareCircleBookUseCase();

    ActiveAccount.setNpub('npub1my_npub');
  });

  tearDown(() {
    ActiveAccount.setNpub(null);
  });

  ShareCircleCubit buildCubit() => ShareCircleCubit(
    mockContactService,
    mockCircleStore,
    mockMarmot,
    mockShareUseCase,
  );

  group('ShareCircleCubit', () {
    test('isValidNpub returns true for valid npub', () {
      final cubit = buildCubit();
      // Use a sample valid npub
      expect(
        cubit.isValidNpub(
          'npub1v4v5td3r04f3n6udfqqv7eulx328y83tndq889yey8n3cnhrntsq8v0wps',
        ),
        true,
      );
    });

    test('isValidNpub returns false for invalid npub', () {
      final cubit = buildCubit();
      expect(cubit.isValidNpub('invalid_npub'), false);
    });

    test('load loads friends and existing members', () async {
      when(
        () => mockContactService.friends,
      ).thenAnswer((_) => Stream.value([const Contact(npub: 'npub1abc')]));
      when(
        () => mockCircleStore.currentCircles,
      ).thenReturn([_createTestBook('group_1', 'Test Book')]);
      // mockMarmot.getMembers returns list of Members.
      // The stub needs to return something that has pubkeyHex.
      when(() => mockMarmot.getMembers('group_1')).thenAnswer(
        (_) async => [
          const MarmotMember(
            npub: 'npub1test123',
            pubkeyHex:
                '7fa56f5d6962ab1e3cdce7373ae0cce438be06466f272c72b2ff8eb88d4d7a8e',
          ),
        ],
      );

      final cubit = buildCubit();
      await cubit.load('group_1');

      expect(cubit.state, isA<ShareCircleLoaded>());
      final state = cubit.state as ShareCircleLoaded;
      expect(state.friends.length, 1);
      expect(state.existingMembers.isNotEmpty, true);
    });

    test('toggleNpub adds and removes npub from selection', () async {
      when(
        () => mockContactService.friends,
      ).thenAnswer((_) => Stream.value([]));
      when(() => mockCircleStore.currentCircles).thenReturn([]);
      when(() => mockMarmot.getMembers(any())).thenAnswer((_) async => []);

      final cubit = buildCubit();
      await cubit.load('group_1');

      cubit.toggleNpub('npub1test');
      expect(
        (cubit.state as ShareCircleLoaded).selectedNpubs.contains('npub1test'),
        true,
      );

      cubit.toggleNpub('npub1test');
      expect(
        (cubit.state as ShareCircleLoaded).selectedNpubs.contains('npub1test'),
        false,
      );
    });

    test('addNpub adds npub if not present', () async {
      when(
        () => mockContactService.friends,
      ).thenAnswer((_) => Stream.value([]));
      when(() => mockCircleStore.currentCircles).thenReturn([]);
      when(() => mockMarmot.getMembers(any())).thenAnswer((_) async => []);

      final cubit = buildCubit();
      await cubit.load('group_1');

      await cubit.addNpub('npub1new');
      expect(
        (cubit.state as ShareCircleLoaded).selectedNpubs.contains('npub1new'),
        true,
      );
    });

    test('share invokes usecase and returns skips', () async {
      when(
        () => mockContactService.friends,
      ).thenAnswer((_) => Stream.value([]));
      when(() => mockCircleStore.currentCircles).thenReturn([]);
      when(() => mockMarmot.getMembers(any())).thenAnswer((_) async => []);

      final skips = [
        const ShareSkip(npub: 'npub1new', reason: ShareSkipReason.noKeyPackage),
      ];
      when(
        () => mockShareUseCase(
          circleBookId: 'group_1',
          npubs: ['npub1new'],
          myNpub: 'npub1my_npub',
        ),
      ).thenAnswer((_) async => skips);

      final cubit = buildCubit();
      await cubit.load('group_1');
      await cubit.addNpub('npub1new');

      final result = await cubit.share('group_1');

      expect(result, skips);
      verify(
        () => mockShareUseCase(
          circleBookId: 'group_1',
          npubs: ['npub1new'],
          myNpub: 'npub1my_npub',
        ),
      ).called(1);
    });

    test('share rethrows on error and clears busy state', () async {
      when(
        () => mockContactService.friends,
      ).thenAnswer((_) => Stream.value([]));
      when(() => mockCircleStore.currentCircles).thenReturn([]);
      when(() => mockMarmot.getMembers(any())).thenAnswer((_) async => []);

      when(
        () => mockShareUseCase(
          circleBookId: 'group_1',
          npubs: ['npub1new'],
          myNpub: 'npub1my_npub',
        ),
      ).thenThrow(Exception('Share failed'));

      final cubit = buildCubit();
      await cubit.load('group_1');
      await cubit.addNpub('npub1new');

      await expectLater(() => cubit.share('group_1'), throwsException);
      expect(cubit.state, isA<ShareCircleLoaded>());
    });
  });
}

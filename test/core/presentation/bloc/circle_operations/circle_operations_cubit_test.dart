import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:zapbook/features/circles/domain/usecases/circles_usecases.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/presentation/bloc/circle_operations/circle_operations_cubit.dart';
import 'package:zapbook/core/presentation/bloc/circle_operations/circle_operations_state.dart';
import 'package:zapbook/zbf/enums/book_source_format.dart';

class MockGetMyNpubUseCase extends Mock implements GetMyNpubUseCase {}

class MockDeleteCircleBookUseCase extends Mock
    implements DeleteCircleBookUseCase {}

class MockLeaveCircleBookUseCase extends Mock
    implements LeaveCircleBookUseCase {}

class MockPrepareCircleCoverUseCase extends Mock
    implements PrepareCircleCoverUseCase {}

class MockUpdateCircleBookMetadataUseCase extends Mock
    implements UpdateCircleBookMetadataUseCase {}

class MockSetUploadingCoverUseCase extends Mock
    implements SetUploadingCoverUseCase {}

class MockClearUploadingCoverUseCase extends Mock
    implements ClearUploadingCoverUseCase {}

class MockUpdateCircleBookCoverOptimisticUseCase extends Mock
    implements UpdateCircleBookCoverOptimisticUseCase {}

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
  late MockGetMyNpubUseCase getMyNpub;
  late MockDeleteCircleBookUseCase deleteBookUseCase;
  late MockLeaveCircleBookUseCase leaveBookUseCase;
  late MockPrepareCircleCoverUseCase prepareCoverUseCase;
  late MockUpdateCircleBookMetadataUseCase updateMetadataUseCase;
  late MockSetUploadingCoverUseCase setUploadingCoverUseCase;
  late MockClearUploadingCoverUseCase clearUploadingCoverUseCase;
  late MockUpdateCircleBookCoverOptimisticUseCase updateCoverOptimisticUseCase;

  setUp(() {
    getMyNpub = MockGetMyNpubUseCase();
    deleteBookUseCase = MockDeleteCircleBookUseCase();
    leaveBookUseCase = MockLeaveCircleBookUseCase();
    prepareCoverUseCase = MockPrepareCircleCoverUseCase();
    updateMetadataUseCase = MockUpdateCircleBookMetadataUseCase();
    setUploadingCoverUseCase = MockSetUploadingCoverUseCase();
    clearUploadingCoverUseCase = MockClearUploadingCoverUseCase();
    updateCoverOptimisticUseCase = MockUpdateCircleBookCoverOptimisticUseCase();

    registerFallbackValue(_createTestBook('dummy', 'dummy', []));
  });

  CircleOperationsCubit buildCubit() => CircleOperationsCubit(
    getMyNpub,
    deleteBookUseCase,
    leaveBookUseCase,
    prepareCoverUseCase,
    updateMetadataUseCase,
    setUploadingCoverUseCase,
    clearUploadingCoverUseCase,
    updateCoverOptimisticUseCase,
  );

  group('CircleOperationsCubit', () {
    final testBook = _createTestBook('book1', 'Test Book', ['npub1admin']);

    test('prepareCover delegates to circleStoreService', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final prepared = GroupImagePrepared(
        encryptedData: Uint8List(0),
        imageHash: Uint8List(0),
        imageKey: Uint8List(0),
        imageNonce: Uint8List(0),
        imageUploadKey: Uint8List(0),
        uploadNsec: '',
        uploadPubkeyHex: '',
        mimeType: '',
        blurhash: 'hash',
        dimensionsWidth: 100,
        dimensionsHeight: 100,
      );
      when(() => prepareCoverUseCase(bytes)).thenAnswer((_) async => prepared);

      final cubit = buildCubit();
      final result = await cubit.prepareCover(bytes);

      expect(result, prepared);
      verify(() => prepareCoverUseCase(bytes)).called(1);
    });

    test('deleteBook leaves then deletes if not admin', () async {
      when(() => getMyNpub()).thenAnswer((_) async => 'npub1notadmin');
      when(() => leaveBookUseCase(any())).thenAnswer((_) async {});
      when(() => deleteBookUseCase(any())).thenAnswer((_) async {});

      final cubit = buildCubit();
      await cubit.deleteBook(testBook);

      expect(cubit.state, isA<CircleOperationsSuccess>());
      verify(() => leaveBookUseCase(testBook)).called(1);
      verify(() => deleteBookUseCase(testBook)).called(1);
    });

    test('deleteBook deletes directly if admin', () async {
      when(() => getMyNpub()).thenAnswer((_) async => 'npub1admin');
      when(() => deleteBookUseCase(any())).thenAnswer((_) async {});

      final cubit = buildCubit();
      await cubit.deleteBook(testBook);

      expect(cubit.state, isA<CircleOperationsSuccess>());
      verifyNever(() => leaveBookUseCase(any()));
      verify(() => deleteBookUseCase(testBook)).called(1);
    });

    test('deleteBook emits failure on error', () async {
      when(() => getMyNpub()).thenAnswer((_) async => 'npub1admin');
      when(
        () => deleteBookUseCase(any()),
      ).thenThrow(Exception('Delete failed'));

      final cubit = buildCubit();
      await cubit.deleteBook(testBook);

      expect(cubit.state, isA<CircleOperationsFailure>());
    });

    test('updateBookMetadata updates and returns updated book', () async {
      when(
        () => updateMetadataUseCase(
          marmotGroupId: 'book1',
          title: 'New Title',
          author: 'New Author',
          genre: 'Sci-Fi',
        ),
      ).thenAnswer((_) async {});

      final cubit = buildCubit();
      final result = await cubit.updateBookMetadata(
        book: testBook,
        title: 'New Title',
        author: 'New Author',
        genre: 'Sci-Fi',
      );

      expect(result?.title, 'New Title');
      expect(cubit.state, isA<CircleOperationsSuccess>());
    });

    test('updateBookMetadata emits failure on error', () async {
      when(
        () => updateMetadataUseCase(
          marmotGroupId: any(named: 'marmotGroupId'),
          title: any(named: 'title'),
          author: any(named: 'author'),
          genre: any(named: 'genre'),
        ),
      ).thenThrow(Exception('Update failed'));

      final cubit = buildCubit();
      final result = await cubit.updateBookMetadata(
        book: testBook,
        title: 'New Title',
        author: 'New Author',
      );

      expect(result, isNull);
      expect(cubit.state, isA<CircleOperationsFailure>());
    });

    test(
      'saveBookEditsInBackground triggers update without awaiting',
      () async {
        when(
          () => updateMetadataUseCase(
            marmotGroupId: any(named: 'marmotGroupId'),
            title: any(named: 'title'),
            author: any(named: 'author'),
            genre: any(named: 'genre'),
          ),
        ).thenAnswer((_) async {});

        final cubit = buildCubit();
        cubit.saveBookEditsInBackground(
          book: testBook,
          title: 'Bg Title',
          author: 'Bg Author',
        );

        await Future.delayed(Duration.zero);

        verify(
          () => updateMetadataUseCase(
            marmotGroupId: 'book1',
            title: 'Bg Title',
            author: 'Bg Author',
            genre: null,
          ),
        ).called(1);
      },
    );

    test('leaveCircle invokes leave and emits success', () async {
      when(() => leaveBookUseCase(any())).thenAnswer((_) async {});

      final cubit = buildCubit();
      await cubit.leaveCircle(testBook);

      expect(cubit.state, isA<CircleOperationsSuccess>());
      verify(() => leaveBookUseCase(testBook)).called(1);
    });

    test('leaveCircle emits failure on error', () async {
      when(() => leaveBookUseCase(any())).thenThrow(Exception('Leave failed'));

      final cubit = buildCubit();
      await cubit.leaveCircle(testBook);

      expect(cubit.state, isA<CircleOperationsFailure>());
    });

    test('isAdminOf returns true if npub in adminNpubs', () async {
      when(() => getMyNpub()).thenAnswer((_) async => 'npub1admin');
      final cubit = buildCubit();
      final isAdmin = await cubit.isAdminOf(testBook);
      expect(isAdmin, true);
    });

    test('isAdminOf returns false if npub not in adminNpubs', () async {
      when(() => getMyNpub()).thenAnswer((_) async => 'npub1other');
      final cubit = buildCubit();
      final isAdmin = await cubit.isAdminOf(testBook);
      expect(isAdmin, false);
    });

    test('isAdminOf returns false if npub is null', () async {
      when(() => getMyNpub()).thenAnswer((_) async => null);
      final cubit = buildCubit();
      final isAdmin = await cubit.isAdminOf(testBook);
      expect(isAdmin, false);
    });
  });
}

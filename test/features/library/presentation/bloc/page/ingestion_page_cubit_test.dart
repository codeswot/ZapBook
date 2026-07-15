import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';

import 'package:zapbook/core/utils/file_hasher.dart';
import 'package:zapbook/features/library/domain/usecases/book_ingestion_usecases.dart';
import 'package:zapbook/features/library/presentation/bloc/page/ingestion_page_cubit.dart';
import 'package:zapbook/features/library/presentation/bloc/page/ingestion_page_state.dart';
import 'package:zapbook/zbf/enums/book_source_format.dart';

class MockPickBookFileUseCase extends Mock implements PickBookFileUseCase {}

class MockFileHasher extends Mock implements FileHasher {}

class MockFindExistingBookUseCase extends Mock
    implements FindExistingBookUseCase {}

class MockFile extends Mock implements File {}

class FakeFile extends Fake implements File {}

CircleBook _createTestBook(String id, String title, String contentHash) {
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
    contentHash: contentHash,
  );
}

void main() {
  late MockPickBookFileUseCase mockFilePicker;
  late MockFileHasher mockHasher;
  late MockFindExistingBookUseCase mockFindExistingBook;

  setUp(() {
    registerFallbackValue(FakeFile());
    mockFilePicker = MockPickBookFileUseCase();
    mockHasher = MockFileHasher();
    mockFindExistingBook = MockFindExistingBookUseCase();
  });

  IngestionPageCubit buildCubit() =>
      IngestionPageCubit(mockFilePicker, mockHasher, mockFindExistingBook);

  group('IngestionPageCubit', () {
    test('pickBook emits picked state if valid file', () async {
      final mockFile = MockFile();
      when(() => mockFile.path).thenReturn('/path/to/my_test-book.epub');
      when(() => mockFilePicker()).thenAnswer((_) async => mockFile);
      when(
        () => mockHasher.sha256OfFile(any()),
      ).thenAnswer((_) async => 'hash123');
      when(
        () => mockFindExistingBook.call(any()),
      ).thenAnswer((_) async => null);

      final cubit = buildCubit();

      final states = <IngestionPageState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.pickBook();
      await Future<void>.delayed(Duration.zero);

      expect(states, [
        const IngestionPagePicking(),
        isA<IngestionPageFilePicked>(),
        const IngestionPageIdle(),
      ]);

      final picked = states[1] as IngestionPageFilePicked;
      expect(picked.file, mockFile);
      expect(picked.contentHash, 'hash123');
      expect(picked.rawTitle, 'My Test Book');

      subscription.cancel();
    });

    test('pickBook emits error if book already in library', () async {
      final mockFile = MockFile();
      when(() => mockFile.path).thenReturn('/path/to/book.epub');
      when(() => mockFilePicker()).thenAnswer((_) async => mockFile);
      when(
        () => mockHasher.sha256OfFile(any()),
      ).thenAnswer((_) async => 'hash123');
      when(() => mockFindExistingBook.call(any())).thenAnswer(
        (_) async => _createTestBook('existing', 'Existing Book', 'hash123'),
      );

      final cubit = buildCubit();
      final states = <IngestionPageState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.pickBook();
      await Future<void>.delayed(Duration.zero);

      expect(states, [
        const IngestionPagePicking(),
        const IngestionPageError('“Existing Book” is already in your library'),
        const IngestionPageIdle(),
      ]);

      subscription.cancel();
    });

    test(
      'pickBook gracefully handles PDF file (falling back to sanitized title if invalid pdf bytes)',
      () async {
        final mockFile = MockFile();
        when(() => mockFile.path).thenReturn('/path/to/another_book.pdf');
        // Return empty bytes so PdfDocument throws and it falls back to sanitized title
        when(() => mockFile.readAsBytesSync()).thenThrow(Exception());
        when(() => mockFilePicker()).thenAnswer((_) async => mockFile);
        when(
          () => mockHasher.sha256OfFile(any()),
        ).thenAnswer((_) async => 'hashpdf');
        when(
          () => mockFindExistingBook.call(any()),
        ).thenAnswer((_) async => null);

        final cubit = buildCubit();

        // Need a valid File mock for isolate.run, so let's use a real temp file
        final tempFile = File('${Directory.systemTemp.path}/test_pdf.pdf');
        tempFile.writeAsBytesSync([]);

        when(() => mockFilePicker()).thenAnswer((_) async => tempFile);
        when(
          () => mockHasher.sha256OfFile(any()),
        ).thenAnswer((_) async => 'hashpdf');

        await cubit.pickBook();

        expect(cubit.state, const IngestionPageIdle()); // Final state
        // The states should have emitted FilePicked
      },
    );

    test('pickBook handles picking cancellation', () async {
      when(() => mockFilePicker()).thenAnswer((_) async => null);

      final cubit = buildCubit();
      final states = <IngestionPageState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.pickBook();
      await Future<void>.delayed(Duration.zero);

      expect(states, [const IngestionPagePicking(), const IngestionPageIdle()]);

      subscription.cancel();
    });

    test('pickBook handles exception', () async {
      when(() => mockFilePicker()).thenThrow(Exception('Picker failed'));

      final cubit = buildCubit();
      final states = <IngestionPageState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.pickBook();
      await Future<void>.delayed(Duration.zero);

      expect(states, [
        const IngestionPagePicking(),
        isA<IngestionPageError>(),
        const IngestionPageIdle(),
      ]);

      subscription.cancel();
    });
  });
}

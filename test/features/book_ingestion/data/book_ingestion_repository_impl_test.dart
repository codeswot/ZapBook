import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/data/library_file_store.dart';
import 'package:zapbook/core/data/search/book_search_index.dart';
import 'package:zapbook/core/data/search/book_vector_index.dart';
import 'package:zapbook/core/domain/ingestion_progress.dart';
import 'package:zapbook/core/domain/ingestion_stage.dart';
import 'package:zapbook/features/book_ingestion/data/book_ingestion_repository_impl.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/book_extractor.dart';
import 'package:zapbook/zbf/zbf.dart';

class MockBookExtractor extends Mock implements BookExtractor {}

class MockLibraryFileStore extends Mock implements LibraryFileStore {}

class MockBookSearchIndex extends Mock implements BookSearchIndex {}

class MockBookVectorIndex extends Mock implements BookVectorIndex {}

void main() {
  group('BookIngestionRepositoryImpl', () {
    late MockBookExtractor extractor;
    late MockLibraryFileStore fileStore;
    late MockBookSearchIndex searchIndex;
    late MockBookVectorIndex vectorIndex;
    late ZbfWriter writer;
    late BookIngestionRepositoryImpl repository;
    late Directory tempDir;

    setUp(() {
      extractor = MockBookExtractor();
      fileStore = MockLibraryFileStore();
      searchIndex = MockBookSearchIndex();
      vectorIndex = MockBookVectorIndex();
      writer = const ZbfWriter();

      repository = BookIngestionRepositoryImpl(
        extractors: [extractor],
        fileStore: fileStore,
        searchIndex: searchIndex,
        vectorIndex: vectorIndex,
        writer: writer,
      );

      tempDir = Directory.systemTemp.createTempSync('zbf_test');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('ingest returns failed when no extractor supports the file', () async {
      final file = File('test.epub');
      when(() => extractor.supports(file)).thenReturn(false);

      final stream = repository.ingest(file);
      final list = await stream.toList();

      expect(list.length, 1);
      expect(list.first.stage, IngestionStage.error);
    });

    test('ingest successful extraction', () async {
      final file = File('${tempDir.path}/test.epub');
      file.writeAsStringSync('dummy');
      final manifest = BookManifest(
        id: 'book1',
        title: 'Test',
        author: 'Author',
        sourceFormat: BookSourceFormat.epub,
        pageCount: 1,
        chapterCount: 1,
        coverAsset: '',
        createdAt: DateTime.now(),
        needsAiProcessing: false,
      );
      final book = ZbfBook(
        manifest: manifest,
        assets: const {},
        fileAssets: const {},
      );
      final progressList = <IngestionProgress>[
        IngestionProgress.extracting(progress: 0.5, currentItem: 'extracting'),
        IngestionProgress.complete(book),
      ];

      when(() => extractor.supports(file)).thenReturn(true);
      when(() => fileStore.bookDir(any())).thenAnswer((_) async => tempDir);
      when(
        () => extractor.extract(
          file,
          circleBookId: any(named: 'circleBookId'),
          outputDirectory: any(named: 'outputDirectory'),
          wizardDataFuture: null,
        ),
      ).thenAnswer((_) => Stream.fromIterable(progressList));
      when(
        () => searchIndex.ensureIndexed('book1', any()),
      ).thenAnswer((_) async {});
      when(
        () => vectorIndex.ensureEmbedded('book1', any()),
      ).thenAnswer((_) async {});

      final stream = repository.ingest(file);
      final events = await stream.toList();

      expect(events.length, 3);
      expect(events[0].stage, IngestionStage.extracting);
      expect(events[1].stage, IngestionStage.writing);
      expect(events[2].stage, IngestionStage.complete);

      verify(() => fileStore.bookDir(any())).called(1);
      verify(() => searchIndex.ensureIndexed('book1', any())).called(1);
      verify(() => vectorIndex.ensureEmbedded('book1', any())).called(1);
      verifyNever(() => fileStore.deleteBook(any())); // No cleanup on success
    });

    test('ingest cleans up on failure', () async {
      final file = File('${tempDir.path}/test.epub');
      if (!file.existsSync()) file.writeAsStringSync('dummy');
      final progressList = <IngestionProgress>[
        IngestionProgress.extracting(progress: 0.5, currentItem: 'extracting'),
        IngestionProgress.failed('Failed to extract'),
      ];

      when(() => extractor.supports(file)).thenReturn(true);
      when(() => fileStore.bookDir(any())).thenAnswer((_) async => tempDir);
      when(
        () => extractor.extract(
          file,
          circleBookId: any(named: 'circleBookId'),
          outputDirectory: any(named: 'outputDirectory'),
          wizardDataFuture: null,
        ),
      ).thenAnswer((_) => Stream.fromIterable(progressList));
      when(() => fileStore.deleteBook(any())).thenAnswer((_) async {});

      final stream = repository.ingest(file, circleDirId: 'test1');
      final events = await stream.toList();

      expect(events.length, 2);
      expect(events[0].stage, IngestionStage.extracting);
      expect(events[1].stage, IngestionStage.error);
      expect(events[1].error, 'Failed to extract');

      verify(() => fileStore.deleteBook('test1')).called(1);
    });

    test('ingest yields error if extraction yields no book', () async {
      final file = File('${tempDir.path}/test.epub');
      if (!file.existsSync()) file.writeAsStringSync('dummy');

      when(() => extractor.supports(file)).thenReturn(true);
      when(() => fileStore.bookDir(any())).thenAnswer((_) async => tempDir);
      when(
        () => extractor.extract(
          file,
          circleBookId: any(named: 'circleBookId'),
          outputDirectory: any(named: 'outputDirectory'),
          wizardDataFuture: null,
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          IngestionProgress.extracting(
            progress: 0.5,
            currentItem: 'extracting',
          ),
        ]),
      );
      when(() => fileStore.deleteBook(any())).thenAnswer((_) async {});

      final stream = repository.ingest(file, circleDirId: 'test1');
      final events = await stream.toList();

      expect(events.length, 2);
      expect(events.last.stage, IngestionStage.error);

      verify(() => fileStore.deleteBook('test1')).called(1);
    });
  });
}

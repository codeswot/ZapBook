import 'package:zapbook/core/domain/usecases/pdf_usecases.dart';
import 'package:zapbook/core/models/book_download_progress.dart';
import 'dart:async';
import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/features/book_reader/domain/usecases/book_reader_usecases.dart';
import 'package:zapbook/core/domain/book_segment_source.dart';

import 'package:zapbook/features/book_reader/presentation/bloc/viewer/zbf_viewer_cubit.dart';
import 'package:zapbook/zbf/zbf.dart';

class MockPdfPageRasterizer extends Mock implements RasterizePdfPageUseCase {}

class MockPdfChunkExtractor extends Mock implements ExtractPdfChunkUseCase {}

class MockSaveBookContentUseCase extends Mock
    implements SaveBookContentUseCase {}

class MockGetBookContentUseCase extends Mock implements GetBookContentUseCase {}

class MockWatchBookDownloadProgressUseCase extends Mock
    implements WatchBookDownloadProgressUseCase {}

void main() {
  late MockPdfPageRasterizer rasterizer;
  late MockPdfChunkExtractor chunkExtractor;
  late MockSaveBookContentUseCase saveBookContent;
  late MockGetBookContentUseCase getBookContent;
  late MockWatchBookDownloadProgressUseCase watchBookDownloadProgress;
  late BookManifest manifest;
  late ZbfBookHandle handle;

  setUp(() {
    rasterizer = MockPdfPageRasterizer();
    chunkExtractor = MockPdfChunkExtractor();
    saveBookContent = MockSaveBookContentUseCase();
    getBookContent = MockGetBookContentUseCase();
    watchBookDownloadProgress = MockWatchBookDownloadProgressUseCase();

    manifest = BookManifest(
      id: 'book_id',
      title: 'Title',
      author: 'Author',
      sourceFormat: BookSourceFormat.epub,
      pageCount: 10,
      chapterCount: 1,
      coverAsset: '',
      createdAt: DateTime.now(),
      needsAiProcessing: false,
      skippablePages: const [],
    );

    handle = ZbfBookHandle(dirPath: '', manifest: manifest);

    when(
      () => watchBookDownloadProgress(),
    ).thenAnswer((_) => const Stream.empty());

    when(() => getBookContent(any())).thenAnswer((_) async => {});
  });

  ZbfViewerCubit createCubit({int initialPage = 0}) {
    return ZbfViewerCubit(
      handle: handle,
      segmentLoader: (pageIndex) async => null,
      rasterizePdfPage: rasterizer,
      extractPdfChunk: chunkExtractor,
      saveBookContent: saveBookContent,
      getBookContent: getBookContent,
      watchBookDownloadProgress: watchBookDownloadProgress,
      initialPage: initialPage,
    );
  }

  group('ZbfViewerCubit', () {
    test('initializes with correct page', () {
      final cubit = createCubit(initialPage: 2);
      expect(cubit.state.currentPage, 2);
    });

    test('nextPage advances and skips skippable pages', () {
      handle = ZbfBookHandle(
        dirPath: '',
        manifest: manifest.copyWith(skippablePages: [1]),
      );
      final cubit = createCubit(initialPage: 0);

      cubit.nextPage();
      expect(cubit.state.currentPage, 2);
    });

    test('previousPage goes back and skips skippable pages', () {
      handle = ZbfBookHandle(
        dirPath: '',
        manifest: manifest.copyWith(skippablePages: [1]),
      );
      final cubit = createCubit(initialPage: 2);

      cubit.previousPage();
      expect(cubit.state.currentPage, 0);
    });

    test('pageChanged updates page and queues prefetch', () {
      final cubit = createCubit(initialPage: 0);

      cubit.pageChanged(5);
      expect(cubit.state.currentPage, 5);
    });

    test('goToPage updates page', () {
      final cubit = createCubit(initialPage: 0);
      cubit.goToPage(5);
      expect(cubit.state.currentPage, 5);

      cubit.goToPage(500);
      expect(cubit.state.currentPage, 5);
    });

    test('segment loader is triggered', () async {
      bool loaderCalled = false;
      final cubit = ZbfViewerCubit(
        handle: handle,
        segmentLoader: (pageIndex) async {
          loaderCalled = true;
          return SegmentData(
            pageStart: 0,
            pages: [
              const BookPage(
                pageNumber: 1,
                chapterIndex: 1,
                chapterTitle: '',
                layoutType: BookLayoutType.textHeavy,
                needsAiProcessing: false,
                blocks: [],
              ),
            ],
            assets: {},
          );
        },
        rasterizePdfPage: rasterizer,
        extractPdfChunk: chunkExtractor,
        saveBookContent: saveBookContent,
        getBookContent: getBookContent,
        watchBookDownloadProgress: watchBookDownloadProgress,
        initialPage: 0,
      );

      await Future.delayed(const Duration(milliseconds: 100));
      expect(loaderCalled, true);
      expect(cubit.state.currentPage, 0);
    });

    test('hydrateFromCache updates pages and triggers reconcile', () async {
      when(() => getBookContent(any())).thenAnswer(
        (_) async => {
          0: const BookPage(
            pageNumber: 1,
            chapterIndex: 0,
            chapterTitle: 'Hydrated',
            layoutType: BookLayoutType.textHeavy,
            needsAiProcessing: false,
            blocks: [],
          ),
        },
      );

      final cubit = createCubit(initialPage: 0);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(cubit.handle.pageAt(0).chapterTitle, 'Hydrated');
    });

    test('progress stream triggers reconcile', () async {
      final controller = StreamController<BookDownloadProgress>();
      when(
        () => watchBookDownloadProgress(),
      ).thenAnswer((_) => controller.stream);

      final cubit = createCubit(initialPage: 0);
      cubit.emit(cubit.state.copyWith(failedPages: {0}));

      cubit.handle.updatePage(
        0,
        const BookPage(
          pageNumber: 1,
          chapterIndex: 0,
          chapterTitle: '',
          layoutType: BookLayoutType.processing,
          needsAiProcessing: true,
          blocks: [],
        ),
      );

      controller.add(const BookDownloadProgress('book_id'));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(cubit.state.failedPages, {0});

      cubit.handle.updatePage(
        0,
        const BookPage(
          pageNumber: 1,
          chapterIndex: 0,
          chapterTitle: '',
          layoutType: BookLayoutType.textHeavy,
          needsAiProcessing: true,
          blocks: [],
        ),
      );

      controller.add(const BookDownloadProgress('book_id'));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(cubit.state.failedPages, isEmpty);
      await controller.close();
    });

    test('extracts chunk when reaching processing page', () async {
      final tempDir = Directory.systemTemp.createTempSync('zbf_viewer_test');
      File('${tempDir.path}/original.pdf').writeAsStringSync('dummy');

      final db = sqlite3.open('${tempDir.path}/pages.db');
      db.execute(
        'CREATE TABLE IF NOT EXISTS pages (page_index INTEGER PRIMARY KEY, chapter_index INTEGER, json TEXT)',
      );
      db.close();

      manifest = manifest.copyWith(sourceFormat: BookSourceFormat.pdf);
      handle = ZbfBookHandle(dirPath: tempDir.path, manifest: manifest);

      for (var i = 0; i < 10; i++) {
        handle.updatePage(
          i,
          BookPage(
            pageNumber: i + 1,
            chapterIndex: 0,
            chapterTitle: '',
            layoutType: BookLayoutType.processing,
            needsAiProcessing: false,
            blocks: const [],
          ),
        );
      }

      when(() => chunkExtractor(any(), any(), any(), any(), any())).thenAnswer(
        (_) async => [
          const BookPage(
            pageNumber: 1,
            chapterIndex: 0,
            chapterTitle: 'Extracted',
            layoutType: BookLayoutType.textHeavy,
            needsAiProcessing: false,
            blocks: [],
          ),
        ],
      );
      when(() => saveBookContent(any(), any())).thenAnswer((_) async => {});

      createCubit(initialPage: 0);
      await Future.delayed(const Duration(milliseconds: 100));

      verify(
        () => chunkExtractor(any(), any(), any(), any(), any()),
      ).called(greaterThan(0));
      tempDir.deleteSync(recursive: true);
    });

    test('prefetch queues illustration pages and rasterizes', () async {
      final tempDir = Directory.systemTemp.createTempSync('zbf_viewer_test');
      File('${tempDir.path}/original.pdf').writeAsStringSync('dummy');

      final db = sqlite3.open('${tempDir.path}/pages.db');
      db.execute(
        'CREATE TABLE IF NOT EXISTS pages (page_index INTEGER PRIMARY KEY, chapter_index INTEGER, json TEXT)',
      );
      db.close();

      manifest = manifest.copyWith(sourceFormat: BookSourceFormat.pdf);
      handle = ZbfBookHandle(dirPath: tempDir.path, manifest: manifest);

      handle.updatePage(
        1,
        const BookPage(
          pageNumber: 2,
          chapterIndex: 0,
          chapterTitle: '',
          layoutType: BookLayoutType.illustration,
          needsAiProcessing: false,
          blocks: [],
        ),
      );

      when(() => rasterizer(any(), any())).thenAnswer((_) async => null);

      createCubit(initialPage: 0);
      await Future.delayed(const Duration(milliseconds: 100));

      verify(() => rasterizer(any(), 1)).called(1);
      tempDir.deleteSync(recursive: true);
    });

    test('retryPage removes from failed and re-triggers', () {
      final cubit = createCubit(initialPage: 0);
      cubit.emit(cubit.state.copyWith(failedPages: {0}));
      cubit.retryPage(0);
      expect(cubit.state.failedPages, isEmpty);
    });
  });
}

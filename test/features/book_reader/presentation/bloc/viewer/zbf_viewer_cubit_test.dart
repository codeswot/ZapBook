import 'dart:async';
import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/data/database/dao/page_dao.dart';
import 'package:zapbook/core/domain/book_segment_source.dart';
import 'package:zapbook/core/domain/pdf_chunk_extractor.dart';
import 'package:zapbook/core/domain/pdf_page_rasterizer.dart';
import 'package:zapbook/core/services/circle_share_service.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/viewer/zbf_viewer_cubit.dart';
import 'package:zapbook/zbf/zbf.dart';

class MockPdfPageRasterizer extends Mock implements PdfPageRasterizer {}

class MockPdfChunkExtractor extends Mock implements PdfChunkExtractor {}

class MockPageDao extends Mock implements PageDao {}

class MockCircleShareService extends Mock implements CircleShareService {}

void main() {
  late MockPdfPageRasterizer rasterizer;
  late MockPdfChunkExtractor chunkExtractor;
  late MockPageDao pageCache;
  late MockCircleShareService shareService;
  late BookManifest manifest;
  late ZbfBookHandle handle;

  setUp(() {
    rasterizer = MockPdfPageRasterizer();
    chunkExtractor = MockPdfChunkExtractor();
    pageCache = MockPageDao();
    shareService = MockCircleShareService();

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
      () => shareService.onBookDownloadProgress,
    ).thenAnswer((_) => const Stream.empty());

    when(() => pageCache.load(any())).thenAnswer((_) async => {});
  });

  ZbfViewerCubit createCubit({int initialPage = 0}) {
    return ZbfViewerCubit(
      handle: handle,
      segmentLoader: (pageIndex) async => null,
      rasterizer: rasterizer,
      chunkExtractor: chunkExtractor,
      pageCache: pageCache,
      shareService: shareService,
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
        rasterizer: rasterizer,
        chunkExtractor: chunkExtractor,
        pageCache: pageCache,
        shareService: shareService,
        initialPage: 0,
      );

      await Future.delayed(const Duration(milliseconds: 100));
      expect(loaderCalled, true);
      expect(cubit.state.currentPage, 0);
    });

    test('hydrateFromCache updates pages and triggers reconcile', () async {
      when(() => pageCache.load(any())).thenAnswer(
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
        () => shareService.onBookDownloadProgress,
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

      when(
        () => chunkExtractor.extractRange(any(), any(), any(), any(), any()),
      ).thenAnswer(
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
      when(() => pageCache.saveAll(any(), any())).thenAnswer((_) async => {});

      createCubit(initialPage: 0);
      await Future.delayed(const Duration(milliseconds: 100));

      verify(
        () => chunkExtractor.extractRange(any(), any(), any(), any(), any()),
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

      when(() => rasterizer.render(any(), any())).thenAnswer((_) async => null);

      createCubit(initialPage: 0);
      await Future.delayed(const Duration(milliseconds: 100));

      verify(() => rasterizer.render(any(), 1)).called(1);
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

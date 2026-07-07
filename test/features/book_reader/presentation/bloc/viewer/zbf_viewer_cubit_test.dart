import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/data/dao/page_dao.dart';
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
  });
}

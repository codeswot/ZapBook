import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/core/data/cache/page_cache_store.dart';
import 'package:zapbook/core/domain/book_segment_source.dart';
import 'package:zapbook/core/domain/pdf_chunk_extractor.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/pdf_page_rasterizer.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/viewer/zbf_viewer_state.dart';

class ZbfViewerCubit extends Cubit<ZbfViewerState> {
  ZbfViewerCubit({
    required this.handle,
    this.segmentLoader,
    PdfPageRasterizer? rasterizer,
    PdfChunkExtractor? chunkExtractor,
    PageCacheStore? pageCache,
    int initialPage = 0,
  }) : _rasterizer = rasterizer ?? getIt<PdfPageRasterizer>(),
       _chunkExtractor = chunkExtractor ?? getIt<PdfChunkExtractor>(),
       _pageCache = pageCache ?? getIt<PageCacheStore>(),
       _skippablePageSet = handle.manifest.skippablePages?.toSet() ?? const {},
       super(ZbfViewerState(currentPage: initialPage)) {
    _initialize(initialPage);
  }

  Future<void> _initialize(int initialPage) async {
    await _hydrateFromCache(initialPage);
    if (isClosed) return;
    _ensureSegment(initialPage);
    _prefetch(initialPage);
    _ensureInitialChunk(initialPage);
    _armPrepWatchdog(initialPage);
  }

  Future<void> _hydrateFromCache(int initialPage) async {
    final cached = await _pageCache.load(handle.manifest.id);
    if (isClosed || cached.isEmpty) return;
    final pageCount = handle.manifest.pageCount;
    var changed = false;
    cached.forEach((index, page) {
      if (index >= 0 && index < pageCount) {
        handle.updatePage(index, page);
        changed = true;
      }
    });
    if (!changed || isClosed) return;
    _reconcilePrep();
    emit(state.copyWith(updateTrigger: state.updateTrigger + 1));
  }

  final ZbfBookHandle handle;
  final BookSegmentLoader? segmentLoader;
  final PdfPageRasterizer _rasterizer;
  final PdfChunkExtractor _chunkExtractor;
  final PageCacheStore _pageCache;
  final _logger = Logger('ZbfViewerCubit');

  static const _prepTimeout = Duration(seconds: 8);
  static const _loadTimeout = Duration(seconds: 20);
  static const _window = 3;

  final List<int> _prefetchQueue = [];
  bool _isProcessingQueue = false;
  final Set<int> _scheduledChunks = {0};
  final Set<int> _loadedSegments = {};
  final Set<int> _skippablePageSet;
  Timer? _prepTimer;

  bool _isSkippable(int index) {
    return _skippablePageSet.contains(index);
  }

  void nextPage() {
    var next = state.currentPage + 1;
    while (next < handle.manifest.pageCount - 1 && _isSkippable(next)) {
      next++;
    }
    if (next < handle.manifest.pageCount) pageChanged(next);
  }

  void previousPage() {
    var prev = state.currentPage - 1;
    while (prev > 0 && _isSkippable(prev)) {
      prev--;
    }
    if (prev >= 0) pageChanged(prev);
  }

  void goToPage(int index) {
    if (index < 0 || index >= handle.manifest.pageCount) return;
    pageChanged(index);
  }

  void pageChanged(int index) {
    if (isClosed) return;
    emit(state.copyWith(currentPage: index));

    _ensureSegment(index);
    _ensureSegment(index + ZbfSegmenter.pagesPerSegment);

    final currentChunk = _chunkForPage(index);
    final page = handle.pageAt(index);
    if (page.layoutType == BookLayoutType.processing) {
      _ensureChunkIngested(currentChunk, priorityPage: index);
    }

    final nextChunk = currentChunk + 1;
    final triggerIndex = currentChunk == 0
        ? 4
        : (10 + (currentChunk - 1) * 20 + 10);
    if (index >= triggerIndex) {
      _ensureChunkIngested(nextChunk);
    }

    _prefetch(index);
    _armPrepWatchdog(index);
  }

  int _chunkForPage(int index) => index < 10 ? 0 : 1 + ((index - 10) ~/ 20);

  void _ensureInitialChunk(int index) {
    if (handle.pageAt(index).layoutType != BookLayoutType.processing) return;
    final chunk = _chunkForPage(index);
    _scheduledChunks.remove(chunk);
    _ensureChunkIngested(chunk, priorityPage: index);
  }

  void _armPrepWatchdog(int index) {
    _prepTimer?.cancel();
    if (handle.pageAt(index).layoutType != BookLayoutType.processing) return;
    if (state.failedPages.contains(index)) return;
    _prepTimer = Timer(_prepTimeout, () {
      if (isClosed) return;
      if (handle.pageAt(index).layoutType != BookLayoutType.processing) return;
      _logger.warning(
        'Page $index still preparing after ${_prepTimeout.inSeconds}s; '
        'showing fallback',
      );
      emit(state.copyWith(failedPages: {...state.failedPages, index}));
    });
  }

  void _reconcilePrep() {
    if (state.failedPages.isEmpty) return;
    final remaining = state.failedPages
        .where((i) => handle.pageAt(i).layoutType == BookLayoutType.processing)
        .toSet();
    if (remaining.length != state.failedPages.length) {
      emit(state.copyWith(failedPages: remaining));
    }
  }

  void retryPage(int index) {
    if (isClosed) return;
    if (index < 0 || index >= handle.manifest.pageCount) return;
    if (state.failedPages.contains(index)) {
      emit(state.copyWith(failedPages: state.failedPages.difference({index})));
    }
    final segmentIndex = index ~/ ZbfSegmenter.pagesPerSegment;
    _loadedSegments.remove(segmentIndex);
    _ensureSegment(index);
    if (handle.pageAt(index).layoutType == BookLayoutType.processing) {
      final chunk = _chunkForPage(index);
      _scheduledChunks.remove(chunk);
      _ensureChunkIngested(chunk, priorityPage: index);
    }
    _armPrepWatchdog(index);
  }

  Future<void> _ensureSegment(int pageIndex) async {
    final loader = segmentLoader;
    if (loader == null) return;
    if (pageIndex < 0 || pageIndex >= handle.manifest.pageCount) return;

    final segmentIndex = pageIndex ~/ ZbfSegmenter.pagesPerSegment;
    if (!_loadedSegments.add(segmentIndex)) return;

    try {
      final data = await loader(pageIndex).timeout(_loadTimeout);
      if (data == null) {
        _loadedSegments.remove(segmentIndex);
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!isClosed) retryPage(pageIndex);
        });
        return;
      }
      for (var i = 0; i < data.pages.length; i++) {
        handle.updatePage(data.pageStart + i, data.pages[i]);
      }
      data.assets.forEach(handle.updateAsset);
      if (isClosed) return;
      _reconcilePrep();
      emit(state.copyWith(updateTrigger: state.updateTrigger + 1));
    } catch (error, stack) {
      _loadedSegments.remove(segmentIndex);
      _logger.warning('Segment load failed for page $pageIndex', error, stack);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!isClosed) retryPage(pageIndex);
      });
    }
  }

  Future<void> _ensureChunkIngested(int chunkIndex, {int? priorityPage}) async {
    if (_scheduledChunks.contains(chunkIndex)) return;

    final pdfFilePath = handle.sourceDocumentPath();
    if (pdfFilePath == null) return;

    final pageCount = handle.manifest.pageCount;
    final start = chunkIndex == 0 ? 0 : 10 + (chunkIndex - 1) * 20;
    if (start >= pageCount) return;
    final rawEnd = chunkIndex == 0 ? 9 : start + 19;
    final end = rawEnd >= pageCount ? pageCount - 1 : rawEnd;

    _scheduledChunks.add(chunkIndex);

    if (!_hasProcessingPage(start, end)) return;

    final title = 'Chapter ${chunkIndex + 1}';
    final priority = (priorityPage ?? start).clamp(start, end);

    try {
      final windowEnd = (priority + _window - 1).clamp(start, end);
      await _extractInto(pdfFilePath, priority, windowEnd, title, chunkIndex);

      if (windowEnd < end) {
        await _extractInto(pdfFilePath, windowEnd + 1, end, title, chunkIndex);
      }
      if (priority > start) {
        await _extractInto(pdfFilePath, start, priority - 1, title, chunkIndex);
      }

      if (isClosed) return;
      _prefetch(state.currentPage);
    } catch (e, stack) {
      _logger.severe('Failed to extract chunk $chunkIndex', e, stack);
      _fillProcessingEmpty(start, end, chunkIndex);
    }
  }

  Future<void> _extractInto(
    String pdfFilePath,
    int start,
    int end,
    String title,
    int chunkIndex,
  ) async {
    final pages = await _chunkExtractor
        .extractRange(pdfFilePath, start, end, title, chunkIndex)
        .timeout(_loadTimeout);
    final saved = <int, BookPage>{};
    for (var i = 0; i < pages.length; i++) {
      handle.updatePage(start + i, pages[i]);
      saved[start + i] = pages[i];
    }
    if (isClosed) return;
    unawaited(_pageCache.saveAll(handle.manifest.id, saved));
    _reconcilePrep();
    emit(state.copyWith(updateTrigger: state.updateTrigger + 1));
  }

  bool _hasProcessingPage(int start, int end) {
    for (var i = start; i <= end && i < handle.manifest.pageCount; i++) {
      if (handle.pageAt(i).layoutType == BookLayoutType.processing) return true;
    }
    return false;
  }

  void _fillProcessingEmpty(int start, int end, int chunkIndex) {
    for (var i = start; i <= end && i < handle.manifest.pageCount; i++) {
      if (handle.pageAt(i).layoutType != BookLayoutType.processing) continue;
      handle.updatePage(
        i,
        BookPage(
          pageNumber: i + 1,
          chapterIndex: chunkIndex,
          chapterTitle: 'Chapter ${chunkIndex + 1}',
          layoutType: BookLayoutType.textHeavy,
          needsAiProcessing: false,
          blocks: const [],
        ),
      );
    }
    if (isClosed) return;
    _reconcilePrep();
    emit(state.copyWith(updateTrigger: state.updateTrigger + 1));
  }

  void _prefetch(int centerIndex) {
    final pdfFilePath = handle.sourceDocumentPath();
    if (pdfFilePath == null) return;

    final pagesToQueue = <int>[];
    for (var i = centerIndex; i < centerIndex + 3; i++) {
      if (i < 0 || i >= handle.manifest.pageCount) continue;

      final page = handle.pageAt(i);
      if (page.layoutType == BookLayoutType.processing) continue;
      if (page.layoutType != BookLayoutType.illustration) continue;
      if (state.imagePages.containsKey(i) ||
          state.rasterizingPages.contains(i) ||
          _prefetchQueue.contains(i)) {
        continue;
      }

      pagesToQueue.add(i);
    }

    if (pagesToQueue.isNotEmpty) {
      _prefetchQueue.addAll(pagesToQueue);
      _processQueue(pdfFilePath);
    }
  }

  Future<void> _processQueue(String pdfFilePath) async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    while (_prefetchQueue.isNotEmpty) {
      if (isClosed) break;
      final pageIndex = _prefetchQueue.removeAt(0);
      final page = handle.pageAt(pageIndex);
      if (page.layoutType == BookLayoutType.processing) continue;
      await _rasterizePage(pageIndex, pdfFilePath, page);
    }

    _isProcessingQueue = false;
  }

  Future<void> _rasterizePage(
    int pageIndex,
    String pdfFilePath,
    BookPage page,
  ) async {
    if (isClosed) return;
    emit(
      state.copyWith(rasterizingPages: {...state.rasterizingPages, pageIndex}),
    );

    final imageName = 'page_${page.pageNumber}.png';
    
    final hasExistingImage = page.blocks.any(
      (b) => b is ImageBlock && b.assetRef == imageName,
    );
    final newBlocks = hasExistingImage 
        ? page.blocks 
        : [ImageBlock(assetRef: imageName), ...page.blocks];

    if (handle.hasAsset(imageName)) {
      emit(
        state.copyWith(
          imagePages: {
            ...state.imagePages,
            pageIndex: newBlocks,
          },
          rasterizingPages: state.rasterizingPages.difference({pageIndex}),
        ),
      );
      return;
    }

    try {
      final imageBytes = await _rasterizer.render(
        pdfFilePath,
        page.pageNumber - 1,
      );
      if (isClosed) return;
      if (imageBytes != null) {
        handle.updateAsset(imageName, imageBytes);
        emit(
          state.copyWith(
            imagePages: {
              ...state.imagePages,
              pageIndex: newBlocks,
            },
            rasterizingPages: state.rasterizingPages.difference({pageIndex}),
          ),
        );
        return;
      }
    } catch (e, stack) {
      _logger.severe('Rasterization failed for page $pageIndex', e, stack);
    }

    if (isClosed) return;
    emit(
      state.copyWith(
        rasterizingPages: state.rasterizingPages.difference({pageIndex}),
      ),
    );
  }

  @override
  Future<void> close() {
    _prepTimer?.cancel();
    _prefetchQueue.clear();
    return super.close();
  }
}

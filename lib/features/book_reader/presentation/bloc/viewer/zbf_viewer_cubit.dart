import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:zapbook/zbf/zbf.dart';

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
    int initialPage = 0,
  }) : _rasterizer = rasterizer ?? getIt<PdfPageRasterizer>(),
       _chunkExtractor = chunkExtractor ?? getIt<PdfChunkExtractor>(),
       _skippablePageSet = handle.manifest.skippablePages?.toSet() ?? const {},
       super(ZbfViewerState(currentPage: initialPage)) {
    _ensureSegment(initialPage);
    _prefetch(initialPage);
    _ensureInitialChunk(initialPage);
    _armPrepWatchdog(initialPage);
  }

  final ZbfBookHandle handle;
  final BookSegmentLoader? segmentLoader;
  final PdfPageRasterizer _rasterizer;
  final PdfChunkExtractor _chunkExtractor;
  final _logger = Logger('ZbfViewerCubit');

  static const _prepTimeout = Duration(seconds: 8);
  static const _loadTimeout = Duration(seconds: 20);

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
      _ensureChunkIngested(currentChunk);
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
    _ensureChunkIngested(chunk);
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
      _ensureChunkIngested(chunk);
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
    }
  }

  Future<void> _ensureChunkIngested(int chunkIndex) async {
    if (_scheduledChunks.contains(chunkIndex)) return;

    final pdf = handle.sourceDocument();
    if (pdf == null) return;

    final start = chunkIndex == 0 ? 0 : 10 + (chunkIndex - 1) * 20;
    if (start >= handle.manifest.pageCount) return;
    final end = chunkIndex == 0 ? 9 : start + 19;

    _scheduledChunks.add(chunkIndex);

    try {
      final pages = await _chunkExtractor
          .extractRange(
            pdf,
            start,
            end,
            'Chapter ${chunkIndex + 1}',
            chunkIndex,
          )
          .timeout(_loadTimeout);

      for (var i = 0; i < pages.length; i++) {
        handle.updatePage(start + i, pages[i]);
      }

      if (isClosed) return;
      _reconcilePrep();
      emit(state.copyWith(updateTrigger: state.updateTrigger + 1));

      _prefetch(state.currentPage);
    } catch (e, stack) {
      _logger.severe('Failed to extract chunk $chunkIndex', e, stack);
      for (var i = start; i <= end; i++) {
        if (i < handle.manifest.pageCount) {
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
      }
      if (isClosed) return;
      _reconcilePrep();
      emit(state.copyWith(updateTrigger: state.updateTrigger + 1));
    }
  }

  void _prefetch(int centerIndex) {
    final pdf = handle.sourceDocument();
    if (pdf == null) return;

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
      _processQueue(pdf);
    }
  }

  Future<void> _processQueue(Uint8List pdf) async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    while (_prefetchQueue.isNotEmpty) {
      if (isClosed) break;
      final pageIndex = _prefetchQueue.removeAt(0);
      final page = handle.pageAt(pageIndex);
      if (page.layoutType == BookLayoutType.processing) continue;
      await _rasterizePage(pageIndex, pdf, page);
    }

    _isProcessingQueue = false;
  }

  Future<void> _rasterizePage(
    int pageIndex,
    Uint8List pdf,
    BookPage page,
  ) async {
    if (isClosed) return;
    emit(
      state.copyWith(rasterizingPages: {...state.rasterizingPages, pageIndex}),
    );

    final imageName = 'page_${page.pageNumber}.png';

    try {
      final imageBytes = await _rasterizer.render(pdf, page.pageNumber - 1);
      if (isClosed) return;
      if (imageBytes != null) {
        handle.updateAsset(imageName, imageBytes);
        emit(
          state.copyWith(
            imagePages: {
              ...state.imagePages,
              pageIndex: [ImageBlock(assetRef: imageName), ...page.blocks],
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

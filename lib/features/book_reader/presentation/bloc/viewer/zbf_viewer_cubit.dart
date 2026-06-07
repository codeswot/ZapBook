import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/core/domain/book_segment_source.dart';
import 'package:zapbook/core/domain/pdf_chunk_extractor.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/data/paragraph_merger.dart';
import 'package:zapbook/core/domain/pdf_page_rasterizer.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/viewer/zbf_viewer_state.dart';

class ZbfViewerCubit extends Cubit<ZbfViewerState> {
  ZbfViewerCubit({
    required this.handle,
    this.segmentLoader,
    PdfPageRasterizer? rasterizer,
    PdfChunkExtractor? chunkExtractor,
  })  : _rasterizer = rasterizer ?? getIt<PdfPageRasterizer>(),
        _chunkExtractor = chunkExtractor ?? getIt<PdfChunkExtractor>(),
        super(const ZbfViewerState()) {
    _ensureSegment(0);
    _prefetch(0);
  }

  final ZbfBookHandle handle;
  final BookSegmentLoader? segmentLoader;
  final PdfPageRasterizer _rasterizer;
  final PdfChunkExtractor _chunkExtractor;
  final _logger = Logger('ZbfViewerCubit');

  final List<int> _prefetchQueue = [];
  bool _isProcessingQueue = false;
  final Set<int> _scheduledChunks = {0};
  final Set<int> _loadedSegments = {};

  bool _isSkippable(int index) {
    final page = handle.pageAt(index);
    if (page.layoutType == BookLayoutType.processing) return false;
    if (page.layoutType == BookLayoutType.illustration) return false;
    if (!pageHasContent(page.blocks)) return true;
    return isTableOfContentsPage(page.blocks);
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

    final currentChunk = index < 10 ? 0 : 1 + ((index - 10) ~/ 20);
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
  }

  Future<void> _ensureSegment(int pageIndex) async {
    final loader = segmentLoader;
    if (loader == null) return;
    if (pageIndex < 0 || pageIndex >= handle.manifest.pageCount) return;

    final segmentIndex = pageIndex ~/ ZbfSegmenter.pagesPerSegment;
    if (!_loadedSegments.add(segmentIndex)) return;

    try {
      final data = await loader(pageIndex);
      if (data == null) {
        _loadedSegments.remove(segmentIndex);
        return;
      }
      for (var i = 0; i < data.pages.length; i++) {
        handle.updatePage(data.pageStart + i, data.pages[i]);
      }
      data.assets.forEach(handle.updateAsset);
      if (isClosed) return;
      emit(state.copyWith(updateTrigger: state.updateTrigger + 1));
    } catch (error, stack) {
      _loadedSegments.remove(segmentIndex);
      _logger.warning('Segment load failed for page $pageIndex', error, stack);
    }
  }

  Future<void> _ensureChunkIngested(int chunkIndex) async {
    if (_scheduledChunks.contains(chunkIndex)) return;
    _scheduledChunks.add(chunkIndex);

    final pdf = handle.sourceDocument();
    if (pdf == null) return;

    final start = chunkIndex == 0 ? 0 : 10 + (chunkIndex - 1) * 20;
    if (start >= handle.manifest.pageCount) return;
    final end = chunkIndex == 0 ? 9 : start + 19;

    try {
      final pages = await _chunkExtractor.extractRange(
        pdf,
        start,
        end,
        'Chapter ${chunkIndex + 1}',
        chunkIndex,
      );

      for (var i = 0; i < pages.length; i++) {
        handle.updatePage(start + i, pages[i]);
      }

      if (isClosed) return;
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
    _prefetchQueue.clear();
    return super.close();
  }
}

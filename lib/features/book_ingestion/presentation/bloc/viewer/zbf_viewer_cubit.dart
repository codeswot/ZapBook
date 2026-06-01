import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/pdf_extractor.dart';
import 'package:zapbook/features/book_ingestion/domain/ai/pdf_page_rasterizer.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/viewer/zbf_viewer_state.dart';

class ZbfViewerCubit extends Cubit<ZbfViewerState> {
  ZbfViewerCubit({required this.handle, PdfPageRasterizer? rasterizer})
    : _rasterizer = rasterizer ?? getIt<PdfPageRasterizer>(),
      super(const ZbfViewerState()) {
    _prefetch(0);
  }

  final ZbfBookHandle handle;
  final PdfPageRasterizer _rasterizer;
  final _logger = Logger('ZbfViewerCubit');

  final List<int> _prefetchQueue = [];
  bool _isProcessingQueue = false;
  final Set<int> _scheduledChunks = {0};

  void nextPage() {
    final next = state.currentPage + 1;
    if (next < handle.manifest.pageCount) pageChanged(next);
  }

  void previousPage() {
    final prev = state.currentPage - 1;
    if (prev >= 0) pageChanged(prev);
  }

  void goToPage(int index) {
    if (index < 0 || index >= handle.manifest.pageCount) return;
    pageChanged(index);
  }

  void pageChanged(int index) {
    if (isClosed) return;
    emit(state.copyWith(currentPage: index));

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

  Future<void> _ensureChunkIngested(int chunkIndex) async {
    if (_scheduledChunks.contains(chunkIndex)) return;
    _scheduledChunks.add(chunkIndex);

    final pdf = handle.sourceDocument();
    if (pdf == null) return;

    final start = chunkIndex == 0 ? 0 : 10 + (chunkIndex - 1) * 20;
    if (start >= handle.manifest.pageCount) return;
    final end = chunkIndex == 0 ? 9 : start + 19;

    try {
      final extractor = PdfExtractor();
      final pages = await extractor.extractRange(
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

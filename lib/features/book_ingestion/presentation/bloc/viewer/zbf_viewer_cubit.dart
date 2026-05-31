import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapbook/features/book_ingestion/domain/usecases/refine_page.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/viewer/zbf_viewer_state.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/pdf_extractor.dart';
import 'package:zapbook/zbf/zbf.dart';

import 'package:logging/logging.dart';

class ZbfViewerCubit extends Cubit<ZbfViewerState> {
  ZbfViewerCubit({
    required this.handle,
    required this.refiner,
  }) : super(const ZbfViewerState()) {
    _prefetch(0);
  }

  final ZbfBookHandle handle;
  final RefinePage refiner;
  final _logger = Logger('ZbfViewerCubit');
  
  final List<int> _prefetchQueue = [];
  bool _isProcessingQueue = false;
  final Set<int> _scheduledChunks = {0};

  void pageChanged(int index) {
    if (isClosed) return;
    emit(state.copyWith(currentPage: index));
    
    final currentChunk = index ~/ 20;
    final page = handle.pageAt(index);
    if (page.layoutType == BookLayoutType.processing) {
      _ensureChunkIngested(currentChunk);
    }

    final nextChunk = currentChunk + 1;
    if (index >= (currentChunk * 20) + 10) {
      _ensureChunkIngested(nextChunk);
    }

    _prefetch(index);
  }

  Future<void> _ensureChunkIngested(int chunkIndex) async {
    if (_scheduledChunks.contains(chunkIndex)) return;
    _scheduledChunks.add(chunkIndex);

    final pdf = handle.sourceDocument();
    if (pdf == null) return;

    final start = chunkIndex * 20;
    if (start >= handle.manifest.pageCount) return;
    final end = start + 19;

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
      if (!page.needsAiProcessing) continue;
      if (state.refinedPages.containsKey(i) || state.refiningPages.contains(i) || _prefetchQueue.contains(i)) continue;

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
      await _refinePage(pageIndex, pdf, page);
    }

    _isProcessingQueue = false;
  }

  Future<void> _refinePage(int pageIndex, Uint8List pdf, BookPage page) async {
    if (isClosed) return;
    emit(state.copyWith(
      refiningPages: {...state.refiningPages, pageIndex},
    ));

    try {
      final refined = await refiner.call(
        sourcePdf: pdf,
        page: page,
        availableAssetRefs: page.blocks
            .whereType<ImageBlock>()
            .map((block) => block.assetRef)
            .toList(),
      );

      if (isClosed) return;

      if (refined != null) {
        emit(state.copyWith(
          refinedPages: {...state.refinedPages, pageIndex: refined},
          refiningPages: state.refiningPages.difference({pageIndex}),
        ));
        return;
      }
    } catch (e, stackTrace) {
      _logger.severe('AI refinement failed for page $pageIndex, falling back to draft blocks', e, stackTrace);
    }

    if (isClosed) return;
    emit(state.copyWith(
      refiningPages: state.refiningPages.difference({pageIndex}),
    ));
  }

  @override
  Future<void> close() {
    _prefetchQueue.clear();
    return super.close();
  }
}

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/features/book_ingestion/domain/entities/ingestion_progress.dart';
import 'package:zapbook/features/book_ingestion/domain/enums/ingestion_stage.dart';
import 'package:zapbook/features/book_ingestion/domain/usecases/ingest_book.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/ingestion_event.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/ingestion_state.dart';
import 'package:zapbook/zbf/zbf.dart';

@injectable
class IngestionBloc extends Bloc<IngestionEvent, IngestionState> {
  IngestionBloc({required this._ingestBook}) : super(const IngestionIdle()) {
    on<IngestionStarted>(_onStarted);
    on<IngestionCancelled>(_onCancelled);
    on<IngestionProgressReported>(_onProgressed);
  }

  final IngestBook _ingestBook;
  StreamSubscription<IngestionProgress>? _subscription;
  IngestionStage _lastStage = IngestionStage.fileSelected;

  Future<void> _onStarted(
    IngestionStarted event,
    Emitter<IngestionState> emit,
  ) async {
    await _subscription?.cancel();
    _lastStage = IngestionStage.fileSelected;
    emit(
      const IngestionInProgress(
        stage: IngestionStage.fileSelected,
        progress: 0,
        currentItem: '',
      ),
    );
    _subscription =
        _ingestBook(
          event.file,
          wizardDataFuture: event.wizardDataFuture,
        ).listen(
          (progress) => add(IngestionProgressReported(progress)),
          onError: (Object error) => add(
            IngestionProgressReported(IngestionProgress.failed('$error')),
          ),
        );
  }

  Future<void> _onCancelled(
    IngestionCancelled event,
    Emitter<IngestionState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = null;
    emit(const IngestionIdle());
  }

  void _onProgressed(
    IngestionProgressReported event,
    Emitter<IngestionState> emit,
  ) {
    final progress = event.progress;
    switch (progress.stage) {
      case IngestionStage.fileSelected:
      case IngestionStage.extracting:
      case IngestionStage.assembling:
      case IngestionStage.writing:
        _lastStage = progress.stage;
        emit(
          IngestionInProgress(
            stage: progress.stage,
            progress: progress.progress,
            currentItem: progress.currentItem,
          ),
        );
      case IngestionStage.needsAiProcessing:
        final result = progress.result;
        if (result != null) {
          emit(
            IngestionNeedsAiProcessing(
              zbfPath: progress.zbfPath ?? '',
              manifest: result.manifest,
              pagesNeedingProcessing: _countPagesNeedingAi(result),
              coverImage: _coverOf(result),
            ),
          );
        }
      case IngestionStage.complete:
        final result = progress.result;
        if (result != null) {
          emit(
            IngestionComplete(
              zbfPath: progress.zbfPath ?? '',
              manifest: result.manifest,
              coverImage: _coverOf(result),
            ),
          );
        }
      case IngestionStage.error:
        emit(
          IngestionFailed(
            error: progress.error ?? 'Unknown error',
            failedAt: _lastStage,
          ),
        );
    }
  }

  Uint8List? _coverOf(ZbfBook? book) {
    if (book == null) {
      return null;
    }
    return book.assets[book.manifest.coverAsset];
  }

  int _countPagesNeedingAi(ZbfBook? book) {
    if (book == null) {
      return 0;
    }
    return book.chapters.fold<int>(
      0,
      (sum, chapter) =>
          sum + chapter.pages.where((page) => page.needsAiProcessing).length,
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

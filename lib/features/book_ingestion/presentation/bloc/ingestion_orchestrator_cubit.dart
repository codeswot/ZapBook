import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:ulid/ulid.dart';
import 'package:zapbook/core/domain/book_ingestion_repository.dart';
import 'package:zapbook/core/domain/ingestion_progress.dart';
import 'package:zapbook/core/domain/ingestion_stage.dart';
import 'package:zapbook/core/domain/wizard_data.dart';
import 'package:zapbook/features/book_ingestion/domain/usecases/ingestion_orchestrator_usecases.dart';

part 'ingestion_orchestrator_state.dart';

@lazySingleton
class IngestionOrchestratorCubit extends Cubit<IngestionOrchestratorState> {
  IngestionOrchestratorCubit(
    this._repository,
    this._createCircleBook,
    this._deleteBookFiles,
    this._finalizeAndUploadBook,
  ) : super(const IngestionOrchestratorState());

  final BookIngestionRepository _repository;
  final CreateCircleBookUseCase _createCircleBook;
  final DeleteBookFilesUseCase _deleteBookFiles;
  final FinalizeAndUploadBookUseCase _finalizeAndUploadBook;

  final Map<String, StreamSubscription<IngestionProgress>> _subscriptions = {};

  String startIngestion(
    File file,
    Future<WizardData> wizardDataFuture,
    String contentHash,
  ) {
    final circleBookId = Ulid().toString();
    final taskState = IngestionTaskState(
      file: file,
      progress: IngestionProgress.fileSelected(
        file.path.split(Platform.pathSeparator).last,
      ),
    );

    wizardDataFuture
        .then((data) {
          _saveCircleBook(circleBookId, data, contentHash);

          final task = state.tasks[circleBookId];
          if (task != null) {
            final newTasks = Map<String, IngestionTaskState>.from(state.tasks);
            newTasks[circleBookId] = task.copyWith(wizardData: data);
            emit(state.copyWith(tasks: newTasks));
          }
        })
        .catchError((_) {
          cancelIngestion(circleBookId);
        });

    final newTasks = Map<String, IngestionTaskState>.from(state.tasks);
    newTasks[circleBookId] = taskState;
    emit(state.copyWith(tasks: newTasks));

    final sub = _repository
        .ingest(
          file,
          wizardDataFuture: wizardDataFuture,
          circleDirId: circleBookId,
        )
        .listen(
          (progress) {
            _updateProgress(circleBookId, progress);
          },
          onError: (e) {
            _updateProgress(
              circleBookId,
              IngestionProgress.failed(e.toString()),
            );
          },
        );

    _subscriptions[circleBookId] = sub;
    return circleBookId;
  }

  void _updateProgress(String circleBookId, IngestionProgress progress) {
    if (!state.tasks.containsKey(circleBookId)) return;

    final task = state.tasks[circleBookId]!;
    final isComplete =
        progress.stage == IngestionStage.complete ||
        progress.stage == IngestionStage.needsAiProcessing;

    final updatedTask = task.copyWith(
      progress: progress,
      isExtractComplete: isComplete || task.isExtractComplete,
    );

    final newTasks = Map<String, IngestionTaskState>.from(state.tasks);
    newTasks[circleBookId] = updatedTask;
    emit(state.copyWith(tasks: newTasks));

    _checkAndTriggerUpload(circleBookId);
  }

  Future<void> _saveCircleBook(
    String circleBookId,
    WizardData data,
    String contentHash,
  ) async {
    if (!state.tasks.containsKey(circleBookId)) return;

   final metadata = {
  if (data.author != null) 'author': data.author,
  if (data.genres.isNotEmpty) 'genres': data.genres,
  'contentHash': contentHash,
};

    final marmotCircleGroupId = await _createCircleBook(
      circleDirId: circleBookId,
      humanTitle: data.title ?? 'Untitled',
      metadata: metadata,
    );

    final task = state.tasks[circleBookId];
    if (task == null) return;
    final newTasks = Map<String, IngestionTaskState>.from(state.tasks);
    newTasks[circleBookId] = task.copyWith(
      isGroupCreated: true,
      marmotGroupId: marmotCircleGroupId,
    );
    emit(state.copyWith(tasks: newTasks));

    _checkAndTriggerUpload(circleBookId);
  }

  Future<void> cancelIngestion(String circleBookId) async {
    final newTasks = Map<String, IngestionTaskState>.from(state.tasks);
    newTasks.remove(circleBookId);
    emit(state.copyWith(tasks: newTasks));

    final sub = _subscriptions.remove(circleBookId);
    await sub?.cancel();

    await _deleteBookFiles(circleBookId);
  }

  void _checkAndTriggerUpload(String circleDirId) async {
    final task = state.tasks[circleDirId];
    if (task == null) return;

    if (task.isGroupCreated && task.isExtractComplete) {
      final marmotGroupId = task.marmotGroupId;
      if (marmotGroupId != null) {
        await _finalizeAndUploadBook(
          circleDirId: circleDirId,
          marmotGroupId: marmotGroupId,
        );
      }

      final newTasks = Map<String, IngestionTaskState>.from(state.tasks);
      newTasks.remove(circleDirId);
      emit(state.copyWith(tasks: newTasks));
    }
  }

  @override
  Future<void> close() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    return super.close();
  }
}

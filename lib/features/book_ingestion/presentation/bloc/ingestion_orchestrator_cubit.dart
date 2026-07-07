import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:ulid/ulid.dart';
import 'package:zapbook/core/data/library_file_store.dart';
import 'package:zapbook/core/domain/book_ingestion_repository.dart';
import 'package:zapbook/core/domain/ingestion_progress.dart';
import 'package:zapbook/core/domain/ingestion_stage.dart';
import 'package:zapbook/core/domain/wizard_data.dart';
import 'package:zapbook/core/identity/active_account.dart';
import 'package:zapbook/core/services/circle_store_service.dart';
import 'package:zapbook/core/services/circle_share_service.dart';
import 'package:zapbook/core/constants/app_constants.dart';
import 'package:mime/mime.dart';

part 'ingestion_orchestrator_state.dart';

@lazySingleton
class IngestionOrchestratorCubit extends Cubit<IngestionOrchestratorState> {
  IngestionOrchestratorCubit(
    this._repository,
    this._circleStore,
    this._circleShareService,
    this._fileStore,
  ) : super(const IngestionOrchestratorState());

  final BookIngestionRepository _repository;
  final CircleStoreService _circleStore;
  final CircleShareService _circleShareService;
  final LibraryFileStore _fileStore;
  final _log = logging.Logger('IngestionOrchestratorCubit');
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
      if (data.genre != null) 'genre': data.genre,
      'contentHash': contentHash,
    };

    final marmotCircleGroupId = await _circleStore.createCircleBook(
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

    try {
      await _fileStore.deleteBook(circleBookId);
    } catch (e, stackTrace) {
      _log.warning(
        'Failed to delete book files for $circleBookId ',
        e,
        stackTrace,
      );
    }
  }

  void _checkAndTriggerUpload(String circleDirId) async {
    final task = state.tasks[circleDirId];
    if (task == null) return;

    if (task.isGroupCreated && task.isExtractComplete) {
      _circleStore.refreshBookCover(circleDirId);

      final npub = ActiveAccount.currentNpub;
      final marmotGroupId = task.marmotGroupId;
      if (npub != null && marmotGroupId != null) {
        _circleShareService.uploadBookContent(npub, marmotGroupId, circleDirId);

        final coverPath = await _fileStore.coverPathIfExists(circleDirId);
        if (coverPath != null) {
          try {
            final coverBytes = await File(coverPath).readAsBytes();
            final preparedImage = await _circleStore.prepareCover(
              coverBytes: coverBytes,
            );
            final mimeType =
                lookupMimeType(coverPath) ?? AppConstants.defaultImageMimeType;

            _circleStore.updateCircleBookCoverOptimistic(
              marmotGroupId: marmotGroupId,
              circleDirId: circleDirId,
              coverBytes: coverBytes,
              preparedImage: preparedImage,
              mimeType: mimeType,
            );
          } catch (e, stackTrace) {
            _log.warning(
              'Failed to update book cover for $circleDirId ',
              e,
              stackTrace,
            );
          }
        }
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

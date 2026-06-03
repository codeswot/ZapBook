import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:ulid/ulid.dart';

import 'package:zapbook/features/book_ingestion/domain/entities/ingestion_progress.dart';
import 'package:zapbook/features/book_ingestion/domain/entities/wizard_data.dart';
import 'package:zapbook/features/book_ingestion/domain/enums/ingestion_stage.dart';
import 'package:zapbook/features/book_ingestion/domain/usecases/ingest_book.dart';
import 'package:zapbook/core/services/file_hasher.dart';
import 'package:zapbook/features/library/domain/entities/ingestion_job.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/domain/enums/ingestion_job_status.dart';
import 'package:zapbook/features/library/domain/usecases/add_book_to_library.dart';
import 'package:zapbook/features/library/domain/usecases/find_book_by_content_hash.dart';
import 'package:zapbook/features/library/presentation/bloc/ingestion_queue_state.dart';

@injectable
class IngestionQueueCubit extends Cubit<IngestionQueueState> {
  IngestionQueueCubit(
    this._ingestBook,
    this._addBookToLibrary,
    this._fileHasher,
    this._findByContentHash,
  ) : super(const IngestionQueueState());

  final IngestBook _ingestBook;
  final AddBookToLibrary _addBookToLibrary;
  final FileHasher _fileHasher;
  final FindBookByContentHash _findByContentHash;

  static const int maxConcurrent = 3;

  final Queue<_PendingFile> _pending = Queue<_PendingFile>();
  final Map<String, StreamSubscription<IngestionProgress>> _running = {};
  final Map<String, String> _hashByJob = {};

  /// Hashes [file] and looks up an already-imported book with the same bytes.
  /// Returns the hash plus the existing book (null when not a duplicate).
  Future<({String hash, LibraryBook? existing})> findDuplicate(
    File file,
  ) async {
    final hash = await _fileHasher.sha256OfFile(file);
    final existing = await _findByContentHash(hash);
    return (hash: hash, existing: existing);
  }

  void enqueue(
    File file, {
    Future<WizardData>? wizardDataFuture,
    String? contentHash,
  }) {
    final job = IngestionJob(id: Ulid().toString(), fileName: _nameOf(file));
    _pending.add(_PendingFile(job.id, file, wizardDataFuture, contentHash));
    emit(state.upsert(job));
    _pump();
  }

  void dismiss(String jobId) {
    if (_running.containsKey(jobId)) {
      return;
    }
    _pending.removeWhere((pending) => pending.jobId == jobId);
    emit(
      IngestionQueueState(
        jobs: state.jobs
            .where((job) => job.id != jobId)
            .toList(growable: false),
      ),
    );
  }

  void _pump() {
    while (_running.length < maxConcurrent && _pending.isNotEmpty) {
      _start(_pending.removeFirst());
    }
  }

  void _start(_PendingFile pending) {
    emit(
      state.patch(
        pending.jobId,
        (job) => job.copyWith(status: IngestionJobStatus.running),
      ),
    );
    if (pending.contentHash != null) {
      _hashByJob[pending.jobId] = pending.contentHash!;
    }
    _running[pending.jobId] =
        _ingestBook(
          pending.file,
          wizardDataFuture: pending.wizardDataFuture,
        ).listen(
          (progress) => _onProgress(pending.jobId, progress),
          onError: (Object error) => _onError(pending.jobId, '$error'),
        );
  }

  Future<void> _onProgress(String jobId, IngestionProgress progress) async {
    switch (progress.stage) {
      case IngestionStage.fileSelected:
      case IngestionStage.extracting:
      case IngestionStage.assembling:
      case IngestionStage.writing:
        emit(
          state.patch(
            jobId,
            (job) => job.copyWith(
              stage: progress.stage,
              progress: progress.progress,
              currentItem: progress.currentItem,
            ),
          ),
        );
      case IngestionStage.complete:
      case IngestionStage.needsAiProcessing:
        await _onWritten(jobId, progress);
      case IngestionStage.error:
        _onError(jobId, progress.error ?? 'Unknown error');
    }
  }

  Future<void> _onWritten(String jobId, IngestionProgress progress) async {
    final book = progress.result;
    final zbfPath = progress.zbfPath;
    if (book == null || zbfPath == null) {
      _onError(jobId, 'Ingestion finished without a written book');
      return;
    }
    try {
      final added = await _addBookToLibrary(
        book,
        zbfPath,
        contentHash: _hashByJob[jobId],
      );
      emit(
        state.patch(
          jobId,
          (job) => job.copyWith(
            status: IngestionJobStatus.success,
            stage: progress.stage,
            progress: 1,
            bookId: added.id,
          ),
        ),
      );
    } on Object catch (error) {
      _onError(jobId, '$error');
      return;
    }
    _finish(jobId);
  }

  void _onError(String jobId, String message) {
    emit(
      state.patch(
        jobId,
        (job) =>
            job.copyWith(status: IngestionJobStatus.failed, error: message),
      ),
    );
    _finish(jobId);
  }

  void _finish(String jobId) {
    _running.remove(jobId)?.cancel();
    _hashByJob.remove(jobId);
    _pump();
  }

  String _nameOf(File file) => file.path.split(Platform.pathSeparator).last;

  @override
  Future<void> close() async {
    for (final subscription in _running.values) {
      await subscription.cancel();
    }
    _running.clear();
    _pending.clear();
    return super.close();
  }
}

final class _PendingFile {
  const _PendingFile(
    this.jobId,
    this.file,
    this.wizardDataFuture,
    this.contentHash,
  );

  final String jobId;
  final File file;
  final Future<WizardData>? wizardDataFuture;
  final String? contentHash;
}

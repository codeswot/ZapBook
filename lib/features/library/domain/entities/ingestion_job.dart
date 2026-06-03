import 'package:equatable/equatable.dart';

import 'package:zapbook/features/book_ingestion/domain/enums/ingestion_stage.dart';
import 'package:zapbook/features/library/domain/enums/ingestion_job_status.dart';

final class IngestionJob extends Equatable {
  const IngestionJob({
    required this.id,
    required this.fileName,
    this.status = IngestionJobStatus.queued,
    this.stage = IngestionStage.fileSelected,
    this.progress = 0,
    this.currentItem = '',
    this.bookId,
    this.error,
  });

  final String id;
  final String fileName;
  final IngestionJobStatus status;
  final IngestionStage stage;
  final double progress;
  final String currentItem;
  final String? bookId;
  final String? error;

  IngestionJob copyWith({
    IngestionJobStatus? status,
    IngestionStage? stage,
    double? progress,
    String? currentItem,
    String? bookId,
    String? error,
  }) {
    return IngestionJob(
      id: id,
      fileName: fileName,
      status: status ?? this.status,
      stage: stage ?? this.stage,
      progress: progress ?? this.progress,
      currentItem: currentItem ?? this.currentItem,
      bookId: bookId ?? this.bookId,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    id,
    fileName,
    status,
    stage,
    progress,
    currentItem,
    bookId,
    error,
  ];
}

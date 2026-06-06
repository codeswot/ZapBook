import 'package:equatable/equatable.dart';

import 'package:zapbook/core/domain/ingestion_stage.dart';
import 'package:zapbook/zbf/zbf.dart';

final class IngestionProgress extends Equatable {
  const IngestionProgress({
    required this.stage,
    required this.progress,
    required this.currentItem,
    this.result,
    this.zbfPath,
    this.error,
  });

  final IngestionStage stage;
  final double progress;
  final String currentItem;
  final ZbfBook? result;
  final String? zbfPath;
  final String? error;

  factory IngestionProgress.fileSelected(String fileName) => IngestionProgress(
    stage: IngestionStage.fileSelected,
    progress: 0,
    currentItem: fileName,
  );

  factory IngestionProgress.extracting({
    required double progress,
    required String currentItem,
  }) => IngestionProgress(
    stage: IngestionStage.extracting,
    progress: progress,
    currentItem: currentItem,
  );

  factory IngestionProgress.assembling(String currentItem) => IngestionProgress(
    stage: IngestionStage.assembling,
    progress: 0.9,
    currentItem: currentItem,
  );

  factory IngestionProgress.writing(String currentItem) => IngestionProgress(
    stage: IngestionStage.writing,
    progress: 0.95,
    currentItem: currentItem,
  );

  factory IngestionProgress.complete(ZbfBook result) => IngestionProgress(
    stage: IngestionStage.complete,
    progress: 1,
    currentItem: result.manifest.title,
    result: result,
  );

  factory IngestionProgress.written({
    required ZbfBook result,
    required String zbfPath,
  }) => IngestionProgress(
    stage: result.manifest.needsAiProcessing
        ? IngestionStage.needsAiProcessing
        : IngestionStage.complete,
    progress: 1,
    currentItem: result.manifest.title,
    result: result,
    zbfPath: zbfPath,
  );

  factory IngestionProgress.failed(String error) => IngestionProgress(
    stage: IngestionStage.error,
    progress: 0,
    currentItem: '',
    error: error,
  );

  @override
  List<Object?> get props => [
    stage,
    progress,
    currentItem,
    result,
    zbfPath,
    error,
  ];
}

import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/features/book_ingestion/domain/enums/ingestion_stage.dart';

sealed class IngestionState extends Equatable {
  const IngestionState();

  @override
  List<Object?> get props => const [];
}

final class IngestionIdle extends IngestionState {
  const IngestionIdle();
}

final class IngestionInProgress extends IngestionState {
  const IngestionInProgress({
    required this.stage,
    required this.progress,
    required this.currentItem,
  });

  final IngestionStage stage;
  final double progress;
  final String currentItem;

  @override
  List<Object?> get props => [stage, progress, currentItem];
}

final class IngestionNeedsAiProcessing extends IngestionState {
  const IngestionNeedsAiProcessing({
    required this.zbfPath,
    required this.pagesNeedingProcessing,
    this.coverImage,
  });

  final String zbfPath;
  final int pagesNeedingProcessing;
  final Uint8List? coverImage;

  @override
  List<Object?> get props => [zbfPath, pagesNeedingProcessing, coverImage];
}

final class IngestionComplete extends IngestionState {
  const IngestionComplete({
    required this.zbfPath,
    required this.manifest,
    this.coverImage,
  });

  final String zbfPath;
  final BookManifest manifest;
  final Uint8List? coverImage;

  @override
  List<Object?> get props => [zbfPath, manifest, coverImage];
}

final class IngestionFailed extends IngestionState {
  const IngestionFailed({required this.error, required this.failedAt});

  final String error;
  final IngestionStage failedAt;

  @override
  List<Object?> get props => [error, failedAt];
}

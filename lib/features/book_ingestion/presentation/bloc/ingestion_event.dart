import 'dart:io';

import 'package:equatable/equatable.dart';

import 'package:zapbook/features/book_ingestion/domain/entities/ingestion_progress.dart';
import 'package:zapbook/features/book_ingestion/domain/entities/wizard_data.dart';

sealed class IngestionEvent extends Equatable {
  const IngestionEvent();

  @override
  List<Object?> get props => const [];
}

final class IngestionStarted extends IngestionEvent {
  const IngestionStarted(this.file, {this.wizardDataFuture});

  final File file;
  final Future<WizardData>? wizardDataFuture;

  @override
  List<Object?> get props => [file.path, wizardDataFuture];
}

final class IngestionCancelled extends IngestionEvent {
  const IngestionCancelled();
}

final class IngestionProgressReported extends IngestionEvent {
  const IngestionProgressReported(this.progress);

  final IngestionProgress progress;

  @override
  List<Object?> get props => [progress];
}

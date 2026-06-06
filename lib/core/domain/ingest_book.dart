import 'dart:io';

import 'package:injectable/injectable.dart';

import 'package:zapbook/core/domain/ingestion_progress.dart';
import 'package:zapbook/core/domain/book_ingestion_repository.dart';

import 'package:zapbook/core/domain/wizard_data.dart';

@injectable
final class IngestBook {
  const IngestBook(this._repository);

  final BookIngestionRepository _repository;

  Stream<IngestionProgress> call(
    File file, {
    Future<WizardData>? wizardDataFuture,
  }) => _repository.ingest(file, wizardDataFuture: wizardDataFuture);
}

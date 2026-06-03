import 'dart:io';

import 'package:zapbook/features/book_ingestion/domain/entities/ingestion_progress.dart';

import 'package:zapbook/features/book_ingestion/domain/entities/wizard_data.dart';

abstract interface class BookIngestionRepository {
  Stream<IngestionProgress> ingest(
    File file, {
    Future<WizardData>? wizardDataFuture,
  });
}

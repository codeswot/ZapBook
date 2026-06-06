import 'dart:io';

import 'package:zapbook/core/domain/ingestion_progress.dart';

import 'package:zapbook/core/domain/wizard_data.dart';

abstract interface class BookIngestionRepository {
  Stream<IngestionProgress> ingest(
    File file, {
    Future<WizardData>? wizardDataFuture,
  });
}

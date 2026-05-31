import 'dart:io';

import 'package:zapbook/features/book_ingestion/domain/entities/ingestion_progress.dart';
import 'package:zapbook/features/book_ingestion/domain/entities/wizard_data.dart';
import 'package:zapbook/zbf/zbf.dart';

abstract interface class BookExtractor {
  BookSourceFormat get format;

  bool supports(File file);

  Stream<IngestionProgress> extract(File file, {Future<WizardData>? wizardDataFuture});
}

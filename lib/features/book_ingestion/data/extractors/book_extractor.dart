import 'dart:io';

import 'package:zapbook/core/domain/ingestion_progress.dart';
import 'package:zapbook/core/domain/wizard_data.dart';
import 'package:zapbook/zbf/zbf.dart';

abstract interface class BookExtractor {
  BookSourceFormat get format;

  bool supports(File file);

  Stream<IngestionProgress> extract(
    File file, {
    Future<WizardData>? wizardDataFuture,
  });
}

import 'dart:io';

import 'package:zapbook/features/book_ingestion/data/documents_directory.dart';

final class FixedDocumentsDirectory implements DocumentsDirectory {
  FixedDocumentsDirectory(this.directory);

  final Directory directory;

  @override
  Future<Directory> resolve() async => directory;
}

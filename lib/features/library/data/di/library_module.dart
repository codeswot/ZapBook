import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/data/documents_directory.dart';
import 'package:zapbook/features/library/data/db/library_database.dart';

@module
abstract class LibraryModule {
  @lazySingleton
  LibraryDatabase libraryDatabase(DocumentsDirectory documents) =>
      LibraryDatabase(_openConnection(documents));
}

LazyDatabase _openConnection(DocumentsDirectory documents) {
  return LazyDatabase(() async {
    final directory = await documents.resolve();
    final file = File('${directory.path}/zapbook_library.sqlite');
    return NativeDatabase.createInBackground(file);
  });
}

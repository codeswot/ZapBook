import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

abstract interface class DocumentsDirectory {
  Future<Directory> resolve();
}

@LazySingleton(as: DocumentsDirectory)
final class PathProviderDocumentsDirectory implements DocumentsDirectory {
  const PathProviderDocumentsDirectory();

  @override
  Future<Directory> resolve() => getApplicationDocumentsDirectory();
}

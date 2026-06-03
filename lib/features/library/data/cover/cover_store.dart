import 'dart:io';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';

import 'package:zapbook/features/book_ingestion/data/documents_directory.dart';

@lazySingleton
final class CoverStore {
  const CoverStore(this._documentsDirectory);

  final DocumentsDirectory _documentsDirectory;

  Future<String?> writeCover(String bookId, Uint8List? bytes) async {
    if (bytes == null || bytes.isEmpty) {
      return null;
    }
    final directory = await _coversDirectory();
    final file = File('${directory.path}/$bookId.png');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> deleteCover(String? path) async {
    if (path == null) {
      return;
    }
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  Future<Directory> _coversDirectory() async {
    final documents = await _documentsDirectory.resolve();
    final covers = Directory('${documents.path}/covers');
    if (!covers.existsSync()) {
      covers.createSync(recursive: true);
    }
    return covers;
  }
}

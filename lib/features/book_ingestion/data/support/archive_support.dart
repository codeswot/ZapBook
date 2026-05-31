import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

extension ArchiveLookup on Archive {
  String? textFile(String path) {
    final file = findFile(path);
    if (file == null) {
      return null;
    }
    return utf8.decode(file.content);
  }

  Uint8List? binaryFile(String path) => findFile(path)?.content;
}

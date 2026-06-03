import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
final class FileHasher {
  const FileHasher();

  Future<String> sha256OfFile(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  String sha256OfBytes(List<int> bytes) => sha256.convert(bytes).toString();
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'dart:isolate';

import 'package:zapbook/zbf/entities/zbf_book.dart';

final class ZbfWriter {
  const ZbfWriter();

  Future<String> write(ZbfBook book, String path) async {
    await Isolate.run(() => const ZbfWriter()._encodeToFile(book, path));
    return path;
  }

  void _encodeToFile(ZbfBook book, String path) {
    final rootDir = Directory(path);
    if (!rootDir.existsSync()) {
      rootDir.createSync(recursive: true);
    }

    final manifestBytes = _encodeJson(book.manifest.toJson());
    File(
      '${rootDir.path}/manifest.json',
    ).writeAsBytesSync(manifestBytes, flush: true);

    final assetsDir = Directory('${rootDir.path}/assets');
    assetsDir.createSync(recursive: true);
    book.assets.forEach((name, bytes) {
      final isRoot = _isRootAsset(name, book.manifest.coverAsset);
      final destPath = isRoot
          ? '${rootDir.path}/$name'
          : '${assetsDir.path}/$name';
      File(destPath).writeAsBytesSync(bytes, flush: true);
    });

    book.fileAssets.forEach((name, filePath) {
      final isRoot = _isRootAsset(name, book.manifest.coverAsset);
      final destPath = isRoot
          ? '${rootDir.path}/$name'
          : '${assetsDir.path}/$name';
      File(filePath).copySync(destPath);
    });
  }

  bool _isRootAsset(String name, String coverAsset) =>
      name == coverAsset || name.startsWith('original.');

  Uint8List _encodeJson(Object? json) {
    return Uint8List.fromList(JsonUtf8Encoder().convert(json));
  }
}

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

  Future<void> _encodeToFile(ZbfBook book, String path) async {
    final rootDir = Directory(path);
    if (!await rootDir.exists()) {
      await rootDir.create(recursive: true);
    }

    final manifestBytes = _encodeJson(book.manifest.toJson());
    final futures = <Future<dynamic>>[
      File('${rootDir.path}/manifest.json').writeAsBytes(manifestBytes),
    ];

    final hasAssets = book.assets.isNotEmpty || book.fileAssets.isNotEmpty;
    final assetsDir = Directory('${rootDir.path}/assets');
    if (hasAssets && !await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }

    book.assets.forEach((name, bytes) {
      final isRoot = _isRootAsset(name, book.manifest.coverAsset);
      final destPath = isRoot
          ? '${rootDir.path}/$name'
          : '${assetsDir.path}/$name';
      futures.add(File(destPath).writeAsBytes(bytes));
    });

    book.fileAssets.forEach((name, filePath) {
      final isRoot = _isRootAsset(name, book.manifest.coverAsset);
      final destPath = isRoot
          ? '${rootDir.path}/$name'
          : '${assetsDir.path}/$name';
      futures.add(File(filePath).copy(destPath));
    });

    await Future.wait(futures);
  }

  bool _isRootAsset(String name, String coverAsset) =>
      name == coverAsset || name.startsWith('original.');

  Uint8List _encodeJson(Object? json) {
    return Uint8List.fromList(JsonUtf8Encoder().convert(json));
  }
}

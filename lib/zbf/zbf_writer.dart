import 'dart:convert';
import 'dart:typed_data';

import 'dart:isolate';

import 'package:archive/archive_io.dart';

import 'package:zapbook/zbf/entities/zbf_book.dart';
import 'package:zapbook/zbf/support/asset_naming.dart';

final class ZbfWriter {
  const ZbfWriter();

  Future<String> write(ZbfBook book, String path) async {
    await Isolate.run(() => const ZbfWriter()._encodeToFile(book, path));
    return path;
  }

  void _encodeToFile(ZbfBook book, String path) {
    final encoder = ZipFileEncoder()..create(path);

    final manifestBytes = _encodeJson(book.manifest.toJson());
    encoder.addArchiveFile(
      ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
    );

    for (final chapter in book.chapters) {
      final name = 'chapters/${AssetNaming.chapterFile(chapter.index)}';
      final bytes = _encodeJson(chapter.toJson());
      encoder.addArchiveFile(ArchiveFile(name, bytes.length, bytes));
    }

    book.assets.forEach((name, bytes) {
      final assetPath = _isRootAsset(name, book.manifest.coverAsset)
          ? name
          : 'assets/$name';
      encoder.addArchiveFile(ArchiveFile(assetPath, bytes.length, bytes));
    });

    encoder.close();
  }

  bool _isRootAsset(String name, String coverAsset) =>
      name == coverAsset || name == AssetNaming.sourceDocument;

  Uint8List _encodeJson(Object? json) {
    return Uint8List.fromList(JsonUtf8Encoder().convert(json));
  }
}

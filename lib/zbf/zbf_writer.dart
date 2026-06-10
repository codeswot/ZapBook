import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'package:zapbook/zbf/entities/zbf_book.dart';
import 'package:zapbook/zbf/support/asset_naming.dart';

final class ZbfWriter {
  const ZbfWriter();

  Uint8List encode(ZbfBook book) {
    final archive = Archive();
    _addManifest(archive, book);
    _addChapters(archive, book);
    _addAssets(archive, book);
    return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
  }

  Future<String> write(ZbfBook book, Directory directory) async {
    final bytes = encode(book);
    final file = File('${directory.path}/${_fileName(book)}');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  void _addManifest(Archive archive, ZbfBook book) {
    final bytes = _encodeJson(book.manifest.toJson());
    archive.addFile(ArchiveFile('manifest.json', bytes.length, bytes));
  }

  void _addChapters(Archive archive, ZbfBook book) {
    for (final chapter in book.chapters) {
      final name = 'chapters/${AssetNaming.chapterFile(chapter.index)}';
      final bytes = _encodeJson(chapter.toJson());
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }
  }

  void _addAssets(Archive archive, ZbfBook book) {
    book.assets.forEach((name, bytes) {
      final path = _isRootAsset(name, book.manifest.coverAsset)
          ? name
          : 'assets/$name';
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    });
  }

  bool _isRootAsset(String name, String coverAsset) =>
      name == coverAsset || name == AssetNaming.sourceDocument;

  Uint8List _encodeJson(Object? json) {
    return Uint8List.fromList(JsonUtf8Encoder().convert(json));
  }

  String _fileName(ZbfBook book) {
    final slug = AssetNaming.slugify(book.manifest.title);
    return '$slug-${book.manifest.id}.zbf';
  }
}

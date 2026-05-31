import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'package:zapbook/zbf/entities/book_chapter.dart';
import 'package:zapbook/zbf/entities/book_manifest.dart';
import 'package:zapbook/zbf/entities/book_page.dart';
import 'package:zapbook/zbf/support/asset_naming.dart';

final class ZbfReader {
  const ZbfReader();

  Future<ZbfBookHandle> open(String path) async {
    final bytes = await File(path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) {
      throw const FormatException('ZBF archive is missing manifest.json');
    }
    final manifest = BookManifest.fromJson(
      _decodeJsonObject(manifestFile.content),
    );
    return ZbfBookHandle(archive: archive, manifest: manifest);
  }

  Future<BookManifest> readManifest(String path) async {
    final handle = await open(path);
    return handle.manifest;
  }
}

final class ZbfBookHandle {
  ZbfBookHandle({required this._archive, required this.manifest});

  final Archive _archive;
  final BookManifest manifest;

  final Map<int, BookChapter> _chapterCache = {};

  BookChapter chapter(int index) {
    return _chapterCache.putIfAbsent(index, () => _decodeChapter(index));
  }

  BookChapter _decodeChapter(int index) {
    final name = 'chapters/${AssetNaming.chapterFile(index)}';
    final file = _archive.findFile(name);
    if (file == null) {
      throw RangeError.index(index, manifest.chapterCount, 'index');
    }
    return BookChapter.fromJson(index, _decodeJsonArray(file.content));
  }

  final Map<int, BookPage> _dynamicallyIngestedPages = {};

  void updatePage(int globalIndex, BookPage page) {
    _dynamicallyIngestedPages[globalIndex] = page;
  }

  BookPage pageAt(int globalIndex) {
    if (_dynamicallyIngestedPages.containsKey(globalIndex)) {
      return _dynamicallyIngestedPages[globalIndex]!;
    }
    if (globalIndex < 0 || globalIndex >= manifest.pageCount) {
      throw RangeError.index(globalIndex, this, 'globalIndex');
    }
    var offset = 0;
    for (final summary in manifest.chapters) {
      if (globalIndex < offset + summary.pageCount) {
        return chapter(summary.index).pages[globalIndex - offset];
      }
      offset += summary.pageCount;
    }
    throw RangeError.index(globalIndex, this, 'globalIndex');
  }

  Iterable<BookChapter> chapters() sync* {
    for (var index = 0; index < manifest.chapterCount; index++) {
      yield chapter(index);
    }
  }

  Uint8List? asset(String name) {
    final isRoot =
        name == manifest.coverAsset || name == AssetNaming.sourceDocument;
    final path = isRoot ? name : 'assets/$name';
    return _archive.findFile(path)?.content;
  }

  Uint8List? sourceDocument() => asset(AssetNaming.sourceDocument);
}

Map<String, Object?> _decodeJsonObject(List<int> bytes) {
  return jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
}

List<Object?> _decodeJsonArray(List<int> bytes) {
  return jsonDecode(utf8.decode(bytes)) as List<Object?>;
}

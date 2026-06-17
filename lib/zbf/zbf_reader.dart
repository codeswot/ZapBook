import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';

import 'package:zapbook/zbf/entities/book_chapter.dart';
import 'package:zapbook/zbf/entities/book_manifest.dart';
import 'package:zapbook/zbf/entities/book_page.dart';
import 'package:zapbook/zbf/support/asset_naming.dart';

final class ZbfReader {
  const ZbfReader();

  Future<ZbfBookHandle> open(String path) async {
    final inputStream = InputFileStream(path);
    final archive = ZipDecoder().decodeStream(inputStream);
    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) {
      await inputStream.close();
      throw const FormatException('ZBF archive is missing manifest.json');
    }
    final manifest = BookManifest.fromJson(
      _decodeJsonObject(manifestFile.content as List<int>),
    );
    return ZbfBookHandle(
      archive: archive,
      manifest: manifest,
      onClose: () => inputStream.close(),
    );
  }

  Future<BookManifest> readManifest(String path) async {
    final handle = await open(path);
    try {
      return handle.manifest;
    } finally {
      handle.close();
    }
  }
}

final class ZbfBookHandle {
  ZbfBookHandle({
    required this._archive,
    required this.manifest,
    this.onClose,
  }) {
    var offset = 0;
    for (final summary in manifest.chapters) {
      _chapterOffsets.add(offset);
      offset += summary.pageCount;
    }
  }

  final Archive _archive;
  final BookManifest manifest;
  final void Function()? onClose;

  void close() {
    onClose?.call();
  }

  static const int _maxCachedChapters = 3;
  final Map<int, BookChapter> _chapterCache = {};
  final List<int> _chapterAccessOrder = [];
  final List<int> _chapterOffsets = [];

  BookChapter chapter(int index) {
    if (_chapterCache.containsKey(index)) {
      _chapterAccessOrder.remove(index);
      _chapterAccessOrder.add(index);
      return _chapterCache[index]!;
    }

    final chapter = _decodeChapter(index);
    _chapterCache[index] = chapter;
    _chapterAccessOrder.add(index);

    if (_chapterAccessOrder.length > _maxCachedChapters) {
      final oldest = _chapterAccessOrder.removeAt(0);
      _chapterCache.remove(oldest);
    }

    return chapter;
  }

  BookChapter _decodeChapter(int index) {
    final name = 'chapters/${AssetNaming.chapterFile(index)}';
    final file = _archive.findFile(name);
    if (file == null) {
      throw RangeError.index(index, manifest.chapterCount, 'index');
    }
    return BookChapter.fromJson(
      index,
      _decodeJsonArray(file.content as List<int>),
    );
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
    var low = 0;
    var high = manifest.chapters.length - 1;
    while (low <= high) {
      final mid = low + ((high - low) >> 1);
      final offset = _chapterOffsets[mid];
      final summary = manifest.chapters[mid];

      if (globalIndex >= offset && globalIndex < offset + summary.pageCount) {
        return chapter(summary.index).pages[globalIndex - offset];
      }
      if (globalIndex < offset) {
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }
    throw RangeError.index(globalIndex, this, 'globalIndex');
  }

  Iterable<BookChapter> chapters() sync* {
    for (var index = 0; index < manifest.chapterCount; index++) {
      yield chapter(index);
    }
  }

  final Map<String, Uint8List> _dynamicAssetCache = {};

  void updateAsset(String name, Uint8List data) {
    _dynamicAssetCache[name] = data;
  }

  Uint8List? asset(String name) {
    if (_dynamicAssetCache.containsKey(name)) {
      return _dynamicAssetCache[name];
    }
    final isRoot =
        name == manifest.coverAsset || name == AssetNaming.sourceDocument;
    final path = isRoot ? name : 'assets/$name';
    final file = _archive.findFile(path);
    if (file == null) {
      return null;
    }
    final content = file.content;
    return content;
  }

  Uint8List? sourceDocument() => asset(AssetNaming.sourceDocument);
}

Map<String, Object?> _decodeJsonObject(List<int> bytes) {
  return utf8.decoder.fuse(const JsonDecoder()).convert(bytes)
      as Map<String, Object?>;
}

List<Object?> _decodeJsonArray(List<int> bytes) {
  return utf8.decoder.fuse(const JsonDecoder()).convert(bytes) as List<Object?>;
}

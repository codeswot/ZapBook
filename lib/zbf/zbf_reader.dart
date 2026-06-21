import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';

import 'package:zapbook/zbf/entities/book_chapter.dart';
import 'package:zapbook/zbf/entities/book_manifest.dart';
import 'package:zapbook/zbf/entities/book_page.dart';
import 'package:zapbook/zbf/support/asset_naming.dart';

final class ZbfReader {
  const ZbfReader();

  Future<ZbfBookHandle> open(String path) async {
    final manifestFile = File('$path/manifest.json');
    if (!manifestFile.existsSync()) {
      throw const FormatException('ZBF directory is missing manifest.json');
    }
    final manifest = BookManifest.fromJson(
      jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>,
    );
    return ZbfBookHandle(dirPath: path, manifest: manifest);
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
  ZbfBookHandle({required this.dirPath, required this.manifest})
    : _db = dirPath.isEmpty
          ? sqlite3.openInMemory()
          : sqlite3.open('$dirPath/pages.db') {
    _db.execute('PRAGMA journal_mode=WAL;');
    if (dirPath.isEmpty) {
      _db.execute(
        'CREATE TABLE pages (page_index INTEGER PRIMARY KEY, chapter_index INTEGER, json TEXT)',
      );
    }
  }

  final String dirPath;
  final BookManifest manifest;
  final Database _db;

  void close() {
    _db.close();
  }

  BookChapter chapter(int index) {
    if (index < 0 || index >= manifest.chapterCount) {
      throw RangeError.index(index, manifest.chapterCount, 'index');
    }
    final summary = manifest.chapters[index];
    final result = _db.select(
      'SELECT json FROM pages WHERE chapter_index = ? ORDER BY page_index ASC',
      [index],
    );
    final pages = result.map((row) {
      return BookPage.fromJson(jsonDecode(row['json'] as String) as Map<String, dynamic>);
    }).toList();
    
    return BookChapter(index: index, title: summary.title, pages: pages);
  }

  void updatePage(int globalIndex, BookPage page) {
    _db.execute(
      'INSERT OR REPLACE INTO pages (page_index, chapter_index, json) VALUES (?, ?, ?)',
      [globalIndex, page.chapterIndex, jsonEncode(page.toJson())],
    );
  }

  BookPage? pageAtOrNull(int globalIndex) {
    if (globalIndex < 0 || globalIndex >= manifest.pageCount) {
      return null;
    }

    final result = _db.select('SELECT json FROM pages WHERE page_index = ?', [
      globalIndex,
    ]);
    if (result.isEmpty) return null;
    return BookPage.fromJson(
      jsonDecode(result.first['json'] as String) as Map<String, dynamic>,
    );
  }

  BookPage pageAt(int globalIndex) {
    if (globalIndex < 0 || globalIndex >= manifest.pageCount) {
      throw RangeError.index(globalIndex, manifest.pageCount, 'globalIndex');
    }

    final result = _db.select('SELECT json FROM pages WHERE page_index = ?', [
      globalIndex,
    ]);
    if (result.isEmpty) {
      throw StateError('Missing page $globalIndex');
    }
    return BookPage.fromJson(
      jsonDecode(result.first['json'] as String) as Map<String, dynamic>,
    );
  }

  Uint8List? get asset {
    if (dirPath.isEmpty) return null;
    final f = File('$dirPath/${AssetNaming.coverAsset}');
    if (!f.existsSync()) return null;
    return f.readAsBytesSync();
  }

  String? sourceDocumentPath() {
    if (dirPath.isEmpty) return null;
    final f = File('$dirPath/${manifest.id}.${manifest.sourceFormat.wireValue}');
    if (f.existsSync()) return f.path;
    return null;
  }

  Iterable<BookChapter> chapters() sync* {
    for (var index = 0; index < manifest.chapterCount; index++) {
      yield chapter(index);
    }
  }

  final Map<String, Uint8List> _dynamicAssetCache = {};

  void updateAsset(String name, Uint8List data) {
    _dynamicAssetCache[name] = data;
    if (dirPath.isNotEmpty) {
      final file = File('$dirPath/assets/$name');
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      file.writeAsBytesSync(data);
    }
  }

  bool hasAsset(String name) {
    if (_dynamicAssetCache.containsKey(name)) return true;
    if (dirPath.isNotEmpty) {
      return File('$dirPath/assets/$name').existsSync();
    }
    return false;
  }

  Uint8List? assetNamed(String name) {
    if (_dynamicAssetCache.containsKey(name)) return _dynamicAssetCache[name]!;
    if (dirPath.isEmpty) return null;
    final f = File('$dirPath/assets/$name');
    if (!f.existsSync()) {
        final f2 = File('$dirPath/$name');
        if (f2.existsSync()) return f2.readAsBytesSync();
        return null;
    }
    return f.readAsBytesSync();
  }
}

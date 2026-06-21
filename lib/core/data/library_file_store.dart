import 'dart:io';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';

import 'package:zapbook/core/identity/account_paths.dart';
import 'package:zapbook/zbf/support/asset_naming.dart';

@lazySingleton
class LibraryFileStore {
  LibraryFileStore();

  static const _libraryDir = 'library';
  static const _segmentDir = 'seg';

  static const _coverName = AssetNaming.coverAsset;

  Directory? _support;
  Directory? _cache;

  Future<Directory> _supportRoot() async =>
      _support ??= await AccountPaths.supportRoot();

  Future<Directory> _cacheRoot() async =>
      _cache ??= await AccountPaths.cacheRoot();

  Future<Directory> bookDir(String bookId) async {
    final root = await _supportRoot();
    return _ensure('${root.path}/$_libraryDir/$bookId');
  }

  Future<String> _bookPath(String bookId) async {
    final root = await _supportRoot();
    return '${root.path}/$_libraryDir/$bookId';
  }

  Future<Directory> zbfFile(String bookId) async =>
      Directory(await _bookPath(bookId));

  Future<File> coverFile(String bookId) async =>
      File('${await _bookPath(bookId)}/$_coverName');

  Future<File> manifestFile(String bookId) async =>
      File('${await _bookPath(bookId)}/manifest.json');

  Future<File> originalFile(String bookId, String extension) async =>
      File('${await _bookPath(bookId)}/original.$extension');

  Future<File> segmentCacheFile(String bookId, int index) async {
    final root = await _cacheRoot();
    final path = '${root.path}/$_libraryDir/$bookId/$_segmentDir';
    return File('$path/${index.toString().padLeft(4, '0')}.zbfpart');
  }

  Future<String> writeZbf(String bookId, Uint8List bytes) async {
    throw UnsupportedError(
      'writeZbf is no longer supported as books are now directories.',
    );
  }

  Future<String?> writeCover(String bookId, Uint8List? bytes) async {
    if (bytes == null || bytes.isEmpty) return null;
    await bookDir(bookId);
    final file = await coverFile(bookId);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<bool> hasZbf(String bookId) async {
    final zbf = await zbfFile(bookId);
    return File('${zbf.path}/manifest.json').existsSync();
  }

  Future<String?> zbfPathIfExists(String bookId) async {
    if (await hasZbf(bookId)) {
      final file = await zbfFile(bookId);
      return file.path;
    }
    return null;
  }

  Future<String?> coverPathIfExists(String bookId) async {
    final file = await coverFile(bookId);
    return file.existsSync() ? file.path : null;
  }

  Future<void> deleteBook(String bookId) async {
    final support = await _supportRoot();
    final durable = Directory('${support.path}/$_libraryDir/$bookId');
    if (durable.existsSync()) await durable.delete(recursive: true);

    final cache = await _cacheRoot();
    final evictable = Directory('${cache.path}/$_libraryDir/$bookId');
    if (evictable.existsSync()) await evictable.delete(recursive: true);
  }

  Future<List<String>> listBookIds() async {
    final root = await _supportRoot();
    final dir = Directory('${root.path}/$_libraryDir');
    if (!dir.existsSync()) return const [];
    return dir
        .listSync()
        .whereType<Directory>()
        .map((entry) => entry.uri.pathSegments.where((s) => s.isNotEmpty).last)
        .toList(growable: false);
  }

  Future<Directory> _ensure(String path) async {
    final dir = Directory(path);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }
}

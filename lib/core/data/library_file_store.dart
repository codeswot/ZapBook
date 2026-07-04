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

  Future<Directory> bookDir(String circleBookId) async {
    final root = await _supportRoot();
    return _ensure('${root.path}/$_libraryDir/$circleBookId');
  }

  Future<String> _bookPath(String circleBookId) async {
    final root = await _supportRoot();
    return '${root.path}/$_libraryDir/$circleBookId';
  }

  Future<Directory> zbfFile(String circleBookId) async =>
      Directory(await _bookPath(circleBookId));

  Future<File> coverFile(String circleBookId, {String? imageHashHex}) async {
    final name = imageHashHex != null ? 'cover_$imageHashHex.jpg' : _coverName;
    return File('${await _bookPath(circleBookId)}/$name');
  }

  Future<File> manifestFile(String circleBookId) async =>
      File('${await _bookPath(circleBookId)}/manifest.json');

  Future<File> originalFile(String circleBookId, String extension) async =>
      File('${await _bookPath(circleBookId)}/original.$extension');

  Future<File> segmentCacheFile(String circleBookId, int index) async {
    final root = await _cacheRoot();
    final path = '${root.path}/$_libraryDir/$circleBookId/$_segmentDir';
    return File('$path/${index.toString().padLeft(4, '0')}.zbfpart');
  }

  Future<String> writeZbf(String circleBookId, Uint8List bytes) async {
    throw UnsupportedError(
      'writeZbf is no longer supported as books are now directories.',
    );
  }

  Future<String?> writeCover(
    String circleBookId,
    Uint8List? bytes, {
    String? imageHashHex,
  }) async {
    if (bytes == null || bytes.isEmpty) return null;
    await bookDir(circleBookId);
    final file = await coverFile(circleBookId, imageHashHex: imageHashHex);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<bool> hasZbf(String circleBookId) async {
    final zbf = await zbfFile(circleBookId);
    return File('${zbf.path}/manifest.json').existsSync();
  }

  Future<String?> zbfPathIfExists(String circleBookId) async {
    if (await hasZbf(circleBookId)) {
      final file = await zbfFile(circleBookId);
      return file.path;
    }
    return null;
  }

  Future<String?> coverPathIfExists(
    String circleBookId, {
    String? imageHashHex,
  }) async {
    if (imageHashHex != null) {
      final hashFile = await coverFile(
        circleBookId,
        imageHashHex: imageHashHex,
      );
      if (await hashFile.exists()) return hashFile.path;
    }
    final file = await coverFile(circleBookId);
    return await file.exists() ? file.path : null;
  }

  Future<void> deleteBook(String circleBookId) async {
    final support = await _supportRoot();
    final durable = Directory('${support.path}/$_libraryDir/$circleBookId');
    if (durable.existsSync()) await durable.delete(recursive: true);

    final cache = await _cacheRoot();
    final evictable = Directory('${cache.path}/$_libraryDir/$circleBookId');
    if (evictable.existsSync()) await evictable.delete(recursive: true);
  }

  Future<List<String>> listcircleBookIds() async {
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

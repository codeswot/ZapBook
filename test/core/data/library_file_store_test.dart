import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/core/data/library_file_store.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async => './test_support';

  @override
  Future<String?> getApplicationCachePath() async => './test_cache';
}

void main() {
  late LibraryFileStore store;

  setUpAll(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  setUp(() {
    store = LibraryFileStore();
  });

  tearDown(() {
    final support = Directory('./test_support');
    if (support.existsSync()) support.deleteSync(recursive: true);
    final cache = Directory('./test_cache');
    if (cache.existsSync()) cache.deleteSync(recursive: true);
  });

  test('bookDir returns directory for book', () async {
    final dir = await store.bookDir('book1');
    expect(dir.path.endsWith('library/book1'), isTrue);
  });

  test('coverFile returns file for cover', () async {
    final file = await store.coverFile('book1');
    expect(file.path.endsWith('library/book1/cover.jpg'), isTrue);
  });

  test('manifestFile returns file for manifest', () async {
    final file = await store.manifestFile('book1');
    expect(file.path.endsWith('library/book1/manifest.json'), isTrue);
  });

  test('originalFile returns file for original', () async {
    final file = await store.originalFile('book1', 'epub');
    expect(file.path.endsWith('library/book1/original.epub'), isTrue);
  });

  test('segmentCacheFile returns cache file', () async {
    final file = await store.segmentCacheFile('book1', 1);
    expect(file.path.endsWith('library/book1/seg/0001.zbfpart'), isTrue);
  });

  test('deleteBook removes book directory', () async {
    final dir = await store.bookDir('book1');
    expect(dir.existsSync(), isTrue);

    await store.deleteBook('book1');
    expect(dir.existsSync(), isFalse);
  });

  test('listcircleBookIds returns list of book ids', () async {
    await store.bookDir('book1');
    await store.bookDir('book2');

    final books = await store.listcircleBookIds();
    expect(books, containsAll(['book1', 'book2']));
  });
}

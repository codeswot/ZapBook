import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/txt_extractor.dart';

import '../../../support/fake_cover_generator.dart';
import '../../../support/fixture_builders.dart';
import '../../../support/temp_files.dart';
import 'package:zapbook/zbf/zbf.dart';

void main() {
  const writer = ZbfWriter();
  const reader = ZbfReader();

  Future<ZbfBook> sampleBook() async {
    final extractor = TxtExtractor(coverGenerator: const FakeCoverGenerator());
    final file = await writeTempFixture('sample.txt', utf8.encode(sampleTxt));
    final result = (await extractor.extract(file).toList()).last.result;
    return result!;
  }

  test('writes a slugified zbf file into the target directory', () async {
    final book = await sampleBook();
    final directory = await createTempDirectory();

    final path = await writer.write(book, directory);

    expect(path, endsWith('.zbf'));
    expect(path, contains(book.manifest.id));
    expect(path, contains('sample'));
  });

  test('archive contains manifest, chapters and cover entries', () async {
    final book = await sampleBook();
    final directory = await createTempDirectory();

    final path = await writer.write(book, directory);
    final archive = ZipDecoder().decodeBytes(await readBytes(path));
    final names = archive.files.map((file) => file.name).toList();

    expect(names, contains('manifest.json'));
    expect(names, contains('cover.png'));
    expect(names, contains('chapters/ch_001.json'));
    expect(names, contains('chapters/ch_002.json'));
  });

  test('reader restores the manifest and lazily loads chapters', () async {
    final book = await sampleBook();
    final directory = await createTempDirectory();
    final path = await writer.write(book, directory);

    final handle = await reader.open(path);

    expect(handle.manifest.title, book.manifest.title);
    expect(handle.manifest.chapterCount, book.chapters.length);

    final firstChapter = handle.chapter(0);
    expect(firstChapter.title, book.chapters.first.title);
    expect(firstChapter.pages.first.blocks.first, isA<HeadingBlock>());
  });

  test('reader exposes the cover asset bytes', () async {
    final book = await sampleBook();
    final directory = await createTempDirectory();
    final path = await writer.write(book, directory);

    final handle = await reader.open(path);

    expect(handle.asset('cover.png'), isNotNull);
  });

  test(
    'manifest carries a chapter table and pageAt maps global pages',
    () async {
      final book = await sampleBook();
      final directory = await createTempDirectory();
      final path = await writer.write(book, directory);

      final handle = await reader.open(path);

      expect(handle.manifest.chapters, hasLength(book.chapters.length));
      expect(handle.manifest.chapters.first.pageCount, 1);

      final firstPage = handle.pageAt(0);
      final lastPage = handle.pageAt(handle.manifest.pageCount - 1);
      expect(firstPage.chapterIndex, 0);
      expect(lastPage.chapterIndex, book.chapters.length - 1);
    },
  );
}

Future<Uint8List> readBytes(String path) async {
  return await File(path).readAsBytes();
}

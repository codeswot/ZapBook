import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/core/data/search/book_search_index.dart';
import 'package:zapbook/zbf/zbf.dart';

void main() {
  late Directory tempDir;
  late BookSearchIndex index;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('book_search_index_test');
    index = BookSearchIndex.forPath('${tempDir.path}/search.db');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<String> writeBook(String id, List<String> pageTexts) async {
    final pages = [
      for (var i = 0; i < pageTexts.length; i++)
        BookPage(
          pageNumber: i + 1,
          chapterIndex: 0,
          chapterTitle: 'Chapter 1',
          layoutType: BookLayoutType.textHeavy,
          needsAiProcessing: false,
          blocks: [ParagraphBlock(text: pageTexts[i])],
        ),
    ];
    final book = ZbfBook(
      manifest: BookManifest(
        id: id,
        title: 'Book $id',
        author: 'Tester',
        sourceFormat: BookSourceFormat.epub,
        pageCount: pages.length,
        chapterCount: 1,
        coverAsset: 'cover.jpg',
        createdAt: DateTime.utc(2026, 1, 1),
        needsAiProcessing: false,
        chapters: [
          ChapterSummary(index: 0, title: 'Chapter 1', pageCount: pages.length),
        ],
      ),
      chapters: [BookChapter(index: 0, title: 'Chapter 1', pages: pages)],
      assets: {
        'cover.jpg': Uint8List.fromList([1]),
      },
    );
    return const ZbfWriter().write(book, '${tempDir.path}/book.zbf');
  }

  test('indexes a book and finds matching pages', () async {
    final path = await writeBook('b1', [
      'The fox jumps over the lazy dog',
      'Bitcoin fixes incentive alignment in distributed systems',
      'Nothing interesting here',
    ]);
    await index.ensureIndexed('b1', path);

    final hits = await index.search('incentive alignment');
    expect(hits, hasLength(1));
    expect(hits.first.bookId, 'b1');
    expect(hits.first.pageNumber, 2);
    expect(hits.first.snippet, contains(BookSearchIndex.highlightStart));
  });

  test('prefix-matches the last term for as-you-type search', () async {
    final path = await writeBook('b2', ['Cryptoeconomics studies incentives']);
    await index.ensureIndexed('b2', path);

    final hits = await index.search('cryptoeco');
    expect(hits, hasLength(1));
  });

  test('scopes search to a single book', () async {
    final p1 = await writeBook('b3', ['shared keyword aurora']);
    final p2 = await writeBook('b4', ['shared keyword aurora again']);
    await index.ensureIndexed('b3', p1);
    await index.ensureIndexed('b4', p2);

    final all = await index.search('aurora');
    expect(all, hasLength(2));
    final scoped = await index.search('aurora', bookId: 'b3');
    expect(scoped, hasLength(1));
    expect(scoped.first.bookId, 'b3');
  });

  test('ensureIndexed is idempotent', () async {
    final path = await writeBook('b5', ['idempotency check passage']);
    await index.ensureIndexed('b5', path);
    await index.ensureIndexed('b5', path);

    final hits = await index.search('idempotency');
    expect(hits, hasLength(1));
  });

  test('remove drops a book from the index', () async {
    final path = await writeBook('b6', ['ephemeral content vanishes']);
    await index.ensureIndexed('b6', path);
    await index.remove('b6');

    expect(await index.search('ephemeral'), isEmpty);
    expect(await index.isIndexed('b6'), isFalse);
  });

  test('hostile query syntax does not throw', () async {
    final path = await writeBook('b7', ['plain text page']);
    await index.ensureIndexed('b7', path);

    expect(await index.search('"unbalanced AND (NOT'), isA<List>());
    expect(await index.search('   '), isEmpty);
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/core/data/cache/page_cache_store.dart';
import 'package:zapbook/zbf/zbf.dart';

void main() {
  late Directory tempDir;
  late PageCacheStore store;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('page_cache_test');
    store = PageCacheStore.forPath('${tempDir.path}/book_pages.db');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  BookPage page(int index) => BookPage(
    pageNumber: index + 1,
    chapterIndex: 1,
    chapterTitle: 'Chapter 2',
    layoutType: BookLayoutType.textHeavy,
    needsAiProcessing: false,
    blocks: [ParagraphBlock(text: 'Body of page ${index + 1}')],
  );

  test('round-trips saved pages by book and index', () async {
    await store.saveAll('book-a', {10: page(10), 11: page(11)});

    final loaded = await store.load('book-a');

    expect(loaded.keys.toSet(), {10, 11});
    expect(loaded[10]!.pageNumber, 11);
    final block = loaded[11]!.blocks.single as ParagraphBlock;
    expect(block.text, 'Body of page 12');
  });

  test('load is empty for an unknown book and scopes by book id', () async {
    await store.saveAll('book-a', {0: page(0)});

    expect(await store.load('book-b'), isEmpty);
  });

  test('remove clears only the targeted book', () async {
    await store.saveAll('book-a', {0: page(0)});
    await store.saveAll('book-b', {0: page(0)});

    await store.remove('book-a');

    expect(await store.load('book-a'), isEmpty);
    expect(await store.load('book-b'), isNotEmpty);
  });

  test('saveAll overwrites an existing page', () async {
    await store.saveAll('book-a', {5: page(5)});
    await store.saveAll('book-a', {
      5: BookPage(
        pageNumber: 6,
        chapterIndex: 1,
        chapterTitle: 'Chapter 2',
        layoutType: BookLayoutType.textHeavy,
        needsAiProcessing: false,
        blocks: [ParagraphBlock(text: 'Rewritten')],
      ),
    });

    final loaded = await store.load('book-a');
    expect((loaded[5]!.blocks.single as ParagraphBlock).text, 'Rewritten');
  });
}

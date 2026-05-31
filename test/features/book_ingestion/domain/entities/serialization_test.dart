import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/zbf/zbf.dart';

void main() {
  test('every block type survives a json round trip', () {
    final blocks = <BookBlock>[
      const HeadingBlock(level: 2, text: 'Title'),
      const ParagraphBlock(text: 'Body'),
      const ImageBlock(assetRef: 'img_001.png', altText: 'alt'),
      const PullquoteBlock(text: 'Quote'),
      const ParagraphBlock(
        text: 'Bold and code',
        runs: [
          TextRun('Bold ', bold: true),
          TextRun('and '),
          TextRun('code', code: true),
        ],
      ),
      const CodeBlock(text: 'print(1)', language: 'dart'),
      const CodeBlock(text: 'noLang()'),
      const CaptionBlock(text: 'Caption'),
      const DividerBlock(),
      const PageBreakBlock(),
    ];

    for (final block in blocks) {
      expect(BookBlock.fromJson(block.toJson()), block);
    }
  });

  test('page round trips through json', () {
    const page = BookPage(
      pageNumber: 3,
      chapterIndex: 1,
      chapterTitle: 'Two',
      layoutType: BookLayoutType.mixed,
      needsAiProcessing: true,
      blocks: [
        ParagraphBlock(text: 'Hello'),
        DividerBlock(),
      ],
    );

    expect(BookPage.fromJson(page.toJson()), page);
  });

  test('chapter rebuilds pages from a json array', () {
    const page = BookPage(
      pageNumber: 1,
      chapterIndex: 0,
      chapterTitle: 'One',
      layoutType: BookLayoutType.textHeavy,
      needsAiProcessing: false,
      blocks: [ParagraphBlock(text: 'Hi')],
    );
    const chapter = BookChapter(index: 0, title: 'One', pages: [page]);

    final restored = BookChapter.fromJson(0, chapter.toJson());

    expect(restored, chapter);
  });

  test('manifest round trips through json', () {
    final manifest = BookManifest(
      id: '01H',
      title: 'Book',
      author: 'Author',
      sourceFormat: BookSourceFormat.epub,
      pageCount: 10,
      chapterCount: 2,
      coverAsset: 'cover.png',
      createdAt: DateTime.utc(2026, 5, 30, 10),
      needsAiProcessing: false,
    );

    expect(BookManifest.fromJson(manifest.toJson()), manifest);
  });
}

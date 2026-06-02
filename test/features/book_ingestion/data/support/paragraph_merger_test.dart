import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/features/book_ingestion/data/support/paragraph_merger.dart';
import 'package:zapbook/zbf/zbf.dart';

void main() {
  const wrapA = ParagraphBlock(
    text: 'It was the best of times, it was the worst of times, it was the',
  );
  const wrapB = ParagraphBlock(
    text: 'age of wisdom, it was the age of foolishness, it was the epoch',
  );

  test('joins wrapped lines with a single space', () {
    final merged = mergeReadingBlocks(const [wrapA, wrapB]);

    expect(merged, hasLength(1));
    expect(
      (merged.single as ParagraphBlock).text,
      'It was the best of times, it was the worst of times, it was the '
      'age of wisdom, it was the age of foolishness, it was the epoch',
    );
  });

  test('keeps a new paragraph when the previous line ends a sentence', () {
    const a = ParagraphBlock(
      text: 'It was the best of times, it was the worst of all the times.',
    );
    const b = ParagraphBlock(
      text: 'A new dawn rose over the silent and the waiting little city.',
    );

    final merged = mergeReadingBlocks(const [a, b]);

    expect(merged, hasLength(2));
  });

  test('treats a short line as an intentional break, not a wrap', () {
    const short = ParagraphBlock(text: 'The end');
    const next = ParagraphBlock(
      text: 'Another long paragraph line that clearly wraps across the width',
    );

    final merged = mergeReadingBlocks(const [short, next]);

    expect(merged, hasLength(2));
  });

  test('reattaches hyphenated words across a wrap without a space', () {
    const a = ParagraphBlock(
      text: 'The quick brown fox jumped over the lazy sleeping water-',
    );
    const b = ParagraphBlock(
      text: 'fall and continued running across the wide open green field',
    );

    final merged = mergeReadingBlocks(const [a, b]);

    expect(merged, hasLength(1));
    expect(
      (merged.single as ParagraphBlock).text,
      contains('waterfall'),
    );
  });

  test('non-paragraph blocks break a run and pass through untouched', () {
    const heading = HeadingBlock(level: 1, text: 'Chapter One');

    final merged = mergeReadingBlocks(const [wrapA, heading, wrapB]);

    expect(merged, hasLength(3));
    expect(merged[1], isA<HeadingBlock>());
  });

  test('merges runs and inserts a separating space run', () {
    const a = ParagraphBlock(
      text: 'It was the best of times, it was the worst of times, it was the',
      runs: [
        TextRun('It was the best of times, it was the worst of times, it '),
        TextRun('was the', bold: true),
      ],
    );
    const b = ParagraphBlock(
      text: 'age of wisdom, it was the age of foolishness, it was the epoch',
      runs: [TextRun('age of wisdom, it was the age of foolishness, it was the epoch')],
    );

    final merged = mergeReadingBlocks(const [a, b]);
    final result = merged.single as ParagraphBlock;

    expect(result.runs, isNotNull);
    expect(result.runs!.map((r) => r.text).join(), result.text);
    expect(result.runs!.any((r) => r.bold), isTrue);
  });

  test('passes through a single block unchanged', () {
    final merged = mergeReadingBlocks(const [wrapA]);
    expect(merged, hasLength(1));
    expect(merged.single, same(wrapA));
  });

  test('strips standalone page-number blocks', () {
    final merged = mergeReadingBlocks(const [
      ParagraphBlock(text: '6'),
      wrapA,
      wrapB,
      ParagraphBlock(text: 'xiv'),
      ParagraphBlock(text: 'Page 12'),
    ]);

    expect(merged, hasLength(1));
    expect((merged.single as ParagraphBlock).text, startsWith('It was'));
  });

  test('strips empty paragraph and heading blocks', () {
    final merged = mergeReadingBlocks(const [
      ParagraphBlock(text: '   '),
      HeadingBlock(level: 1, text: ''),
      wrapA,
    ]);

    expect(merged, hasLength(1));
    expect(merged.single, isA<ParagraphBlock>());
  });

  test('pageHasContent is false for noise-only pages', () {
    expect(
      pageHasContent(const [
        ParagraphBlock(text: '5'),
        ParagraphBlock(text: '   '),
      ]),
      isFalse,
    );
    expect(pageHasContent(const [wrapA]), isTrue);
  });

  test('detects a dot-leader table-of-contents page', () {
    expect(
      isTableOfContentsPage(const [
        ParagraphBlock(text: 'Zaps and Nutzaps 78 ......................'),
        ParagraphBlock(text: '7. Communities 81 .........................'),
        ParagraphBlock(text: 'Digital Architecture 82 ..................'),
        ParagraphBlock(text: 'Social Clusters 83 .......................'),
      ]),
      isTrue,
    );
  });

  test('does not flag normal prose as a table of contents', () {
    expect(
      isTableOfContentsPage(const [wrapA, wrapB, wrapA]),
      isFalse,
    );
  });

  test('does not flag a short page as a table of contents', () {
    expect(
      isTableOfContentsPage(const [
        ParagraphBlock(text: 'Chapter One ......... 5'),
      ]),
      isFalse,
    );
  });

  test('rejoins a word split across two single-token blocks', () {
    final merged = mergeReadingBlocks(const [
      ParagraphBlock(text: 'Slicin'),
      ParagraphBlock(text: 'g'),
    ]);

    expect(merged, hasLength(1));
    expect((merged.single as ParagraphBlock).text, 'Slicing');
  });

  test('does not no-space-glue when the next token is capitalised', () {
    final merged = mergeReadingBlocks(const [
      ParagraphBlock(text: 'Slicin'),
      ParagraphBlock(text: 'Word'),
    ]);

    final joined = merged.whereType<ParagraphBlock>().map((b) => b.text);
    expect(joined, isNot(contains('SlicinWord')));
  });

  test('rejoins a single trailing letter onto a multi-word line', () {
    final merged = mergeReadingBlocks(const [
      ParagraphBlock(text: 'Read our full blog pos'),
      ParagraphBlock(text: 't'),
    ]);

    expect(merged, hasLength(1));
    expect((merged.single as ParagraphBlock).text, 'Read our full blog post');
  });

  test('does not glue a real word onto a multi-word line', () {
    final merged = mergeReadingBlocks(const [
      ParagraphBlock(text: 'The quick brown'),
      ParagraphBlock(text: 'fox'),
    ]);
    final texts = merged.whereType<ParagraphBlock>().map((b) => b.text);
    expect(texts, isNot(contains('The quick brownfox')));
  });
}

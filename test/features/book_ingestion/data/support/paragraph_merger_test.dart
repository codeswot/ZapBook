import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/features/book_ingestion/data/support/paragraph_merger.dart';
import 'package:zapbook/zbf/zbf.dart';

void main() {
  // Long lines (>= 66% of the widest line) read as wraps; short ones as breaks.
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
}

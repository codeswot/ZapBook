import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/core/data/paragraph_merger.dart';
import 'package:zapbook/zbf/zbf.dart';

void main() {
  group('mergeReadingBlocks', () {
    test('drops noise blocks like empty paragraphs and page numbers', () {
      final blocks = [
        const ParagraphBlock(text: ''),
        const ParagraphBlock(text: '12'),
        const HeadingBlock(text: 'Chapter 1', level: 1),
        const ParagraphBlock(text: 'Real content here that is long enough.'),
      ];

      final merged = mergeReadingBlocks(blocks);

      expect(merged.length, 2);
      expect((merged[0] as HeadingBlock).text, 'Chapter 1');
      expect(
        (merged[1] as ParagraphBlock).text,
        'Real content here that is long enough.',
      );
    });

    test('joins hyphen-split word fragments across paragraphs', () {
      final blocks = [
        const ParagraphBlock(text: 'This is a long enough para-'),
        const ParagraphBlock(text: 'graph split by a hyphen.'),
      ];

      final merged = mergeReadingBlocks(blocks);

      expect(merged.length, 1);
      expect(
        (merged[0] as ParagraphBlock).text,
        'This is a long enough paragraph split by a hyphen.',
      );
    });

    test('joins short continuing paragraphs with a space', () {
      final blocks = [
        const ParagraphBlock(
          text: 'This paragraph runs on and does not end with punctuation',
        ),
        const ParagraphBlock(text: 'and this continues the same sentence.'),
      ];

      final merged = mergeReadingBlocks(blocks);

      expect(merged.length, 1);
      expect(
        (merged[0] as ParagraphBlock).text,
        'This paragraph runs on and does not end with punctuation and this continues the same sentence.',
      );
    });

    test('does not join paragraphs when the first ends a sentence', () {
      final blocks = [
        const ParagraphBlock(text: 'A short sentence that ends cleanly.'),
        const ParagraphBlock(text: 'Another separate paragraph follows.'),
      ];

      final merged = mergeReadingBlocks(blocks);

      expect(merged.length, 2);
    });
  });

  group('mergeReadingBlocksWithProvenance', () {
    test('blocks output matches mergeReadingBlocks exactly', () {
      final blocks = [
        const ParagraphBlock(text: ''),
        const ParagraphBlock(text: 'First long enough paragraph runs on'),
        const ParagraphBlock(text: 'and continues here without a period'),
        const HeadingBlock(text: 'Section', level: 2),
        const ParagraphBlock(text: 'Standalone sentence that ends here.'),
      ];

      final classic = mergeReadingBlocks(blocks);
      final result = mergeReadingBlocksWithProvenance(blocks);

      expect(result.blocks.length, classic.length);
      for (var i = 0; i < classic.length; i++) {
        expect(blockPlainText(result.blocks[i]), blockPlainText(classic[i]));
      }
    });

    test('single pass-through block gets one full-coverage run', () {
      final blocks = [const HeadingBlock(text: 'Solo heading', level: 1)];

      final result = mergeReadingBlocksWithProvenance(blocks);

      expect(result.provenance.length, 1);
      final run = result.provenance.single;
      expect(run.mergedBlockIndex, 0);
      expect(run.mergedStart, 0);
      expect(run.mergedEnd, 'Solo heading'.length);
      expect(run.originalBlockIndex, 0);
      expect(run.originalStart, 0);
      expect(run.originalEnd, 'Solo heading'.length);
    });

    test('joined paragraph chain produces one run per original block', () {
      final blocks = [
        const ParagraphBlock(
          text: 'This paragraph runs on and does not end with punctuation',
        ),
        const ParagraphBlock(text: 'and this continues the same sentence.'),
      ];

      final result = mergeReadingBlocksWithProvenance(blocks);
      final merged = result.blocks.single as ParagraphBlock;

      expect(result.provenance.length, 2);
      final first = result.provenance[0];
      final second = result.provenance[1];

      expect(first.originalBlockIndex, 0);
      expect(second.originalBlockIndex, 1);

      expect(
        merged.text.substring(first.mergedStart, first.mergedEnd),
        blocks[0].text.substring(first.originalStart, first.originalEnd),
      );
      expect(
        merged.text.substring(second.mergedStart, second.mergedEnd),
        blocks[1].text.substring(second.originalStart, second.originalEnd),
      );
    });

    test('noise blocks contribute no provenance run', () {
      final blocks = [
        const ParagraphBlock(text: ''),
        const ParagraphBlock(text: '42'),
        const HeadingBlock(text: 'Kept', level: 1),
      ];

      final result = mergeReadingBlocksWithProvenance(blocks);

      expect(result.provenance.length, 1);
      expect(result.provenance.single.originalBlockIndex, 2);
    });

    test('hyphen trim excludes the hyphen from either run', () {
      final blocks = [
        const ParagraphBlock(text: 'This is a long enough para-'),
        const ParagraphBlock(text: 'graph split by a hyphen.'),
      ];

      final result = mergeReadingBlocksWithProvenance(blocks);
      final merged = result.blocks.single as ParagraphBlock;
      final first = result.provenance[0];

      expect(merged.text.contains('para-graph'), isFalse);
      expect(blocks[0].text[first.originalEnd], '-');
    });
  });
}

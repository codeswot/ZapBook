import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/core/data/paragraph_merger.dart';
import 'package:zapbook/features/book_reader/domain/anchor_resolution.dart';
import 'package:zapbook/features/book_reader/domain/entities/highlight.dart';

void main() {
  group('resolveSelectionAnchor', () {
    test('returns null for empty selection', () {
      final spans = resolveSelectionAnchor(
        mergedBlockTexts: ['Hello world'],
        pageRuns: [
          const BlockProvenanceRun(
            mergedBlockIndex: 0,
            mergedStart: 0,
            mergedEnd: 11,
            originalBlockIndex: 0,
            originalStart: 0,
            originalEnd: 11,
          ),
        ],
        selectedText: '   ',
      );

      expect(spans, isNull);
    });

    test('resolves a unique exact match within one block', () {
      final spans = resolveSelectionAnchor(
        mergedBlockTexts: ['The quick brown fox jumps.'],
        pageRuns: [
          const BlockProvenanceRun(
            mergedBlockIndex: 0,
            mergedStart: 0,
            mergedEnd: 26,
            originalBlockIndex: 0,
            originalStart: 0,
            originalEnd: 26,
          ),
        ],
        selectedText: 'quick brown',
      );

      expect(spans, isNotNull);
      expect(spans!.length, 1);
      expect(spans.first.originalBlockIndex, 0);
      expect(spans.first.startOffset, 4);
      expect(spans.first.endOffset, 15);
    });

    test('returns null when the selection is not found anywhere', () {
      final spans = resolveSelectionAnchor(
        mergedBlockTexts: ['The quick brown fox jumps.'],
        pageRuns: [
          const BlockProvenanceRun(
            mergedBlockIndex: 0,
            mergedStart: 0,
            mergedEnd: 26,
            originalBlockIndex: 0,
            originalStart: 0,
            originalEnd: 26,
          ),
        ],
        selectedText: 'nonexistent phrase',
      );

      expect(spans, isNull);
    });

    test('splits a selection crossing two original blocks into two spans', () {
      const mergedText = 'First half second half';
      final spans = resolveSelectionAnchor(
        mergedBlockTexts: [mergedText],
        pageRuns: [
          const BlockProvenanceRun(
            mergedBlockIndex: 0,
            mergedStart: 0,
            mergedEnd: 10,
            originalBlockIndex: 0,
            originalStart: 0,
            originalEnd: 10,
          ),
          const BlockProvenanceRun(
            mergedBlockIndex: 0,
            mergedStart: 10,
            mergedEnd: 23,
            originalBlockIndex: 1,
            originalStart: 0,
            originalEnd: 13,
          ),
        ],
        selectedText: 'half second',
      );

      expect(spans, isNotNull);
      expect(spans!.length, 2);
      expect(spans[0].originalBlockIndex, 0);
      expect(spans[1].originalBlockIndex, 1);
    });

    test('uses the disambiguation hint to pick among repeated matches', () {
      const mergedText = 'echo echo echo';
      final runs = [
        const BlockProvenanceRun(
          mergedBlockIndex: 0,
          mergedStart: 0,
          mergedEnd: 14,
          originalBlockIndex: 0,
          originalStart: 0,
          originalEnd: 14,
        ),
      ];

      final nearStart = resolveSelectionAnchor(
        mergedBlockTexts: [mergedText],
        pageRuns: runs,
        selectedText: 'echo',
        disambiguationHint: 0,
      );
      final nearEnd = resolveSelectionAnchor(
        mergedBlockTexts: [mergedText],
        pageRuns: runs,
        selectedText: 'echo',
        disambiguationHint: 10,
      );

      expect(nearStart!.first.startOffset, 0);
      expect(nearEnd!.first.startOffset, 10);
    });

    test('falls back to whitespace-normalized matching', () {
      const mergedText = 'weird   spacing   here';
      final spans = resolveSelectionAnchor(
        mergedBlockTexts: [mergedText],
        pageRuns: [
          const BlockProvenanceRun(
            mergedBlockIndex: 0,
            mergedStart: 0,
            mergedEnd: mergedText.length,
            originalBlockIndex: 0,
            originalStart: 0,
            originalEnd: mergedText.length,
          ),
        ],
        selectedText: 'weird spacing',
      );

      expect(spans, isNotNull);
      expect(spans!.first.originalBlockIndex, 0);
    });
  });

  group('mapSpansToMergedRanges', () {
    test('maps a single span back to its merged-block-local range', () {
      final ranges = mapSpansToMergedRanges(
        spans: [
          const HighlightSpan(
            originalBlockIndex: 0,
            startOffset: 4,
            endOffset: 9,
          ),
        ],
        pageRuns: [
          const BlockProvenanceRun(
            mergedBlockIndex: 2,
            mergedStart: 0,
            mergedEnd: 20,
            originalBlockIndex: 0,
            originalStart: 0,
            originalEnd: 20,
          ),
        ],
      );

      expect(ranges.keys, [2]);
      expect(ranges[2]!.single.start, 4);
      expect(ranges[2]!.single.end, 9);
    });
  });
}

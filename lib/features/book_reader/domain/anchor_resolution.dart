import 'package:zapbook/core/data/paragraph_merger.dart';
import 'package:zapbook/features/book_reader/domain/entities/highlight.dart';

class _CollapsedText {
  const _CollapsedText(this.text, this.toOriginal);
  final String text;
  final List<int> toOriginal;
}

_CollapsedText _collapseWhitespace(String text) {
  final buffer = StringBuffer();
  final mapping = <int>[];
  var lastWasSpace = false;
  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    final isSpace = char.trim().isEmpty;
    if (isSpace) {
      if (!lastWasSpace) {
        buffer.write(' ');
        mapping.add(i);
      }
      lastWasSpace = true;
    } else {
      buffer.write(char);
      mapping.add(i);
      lastWasSpace = false;
    }
  }
  return _CollapsedText(buffer.toString(), mapping);
}

List<int> _findAllMatches(String haystack, String needle) {
  if (needle.isEmpty) return const [];
  final matches = <int>[];
  var searchStart = 0;
  while (true) {
    final index = haystack.indexOf(needle, searchStart);
    if (index == -1) break;
    matches.add(index);
    searchStart = index + 1;
  }
  return matches;
}

int? _pickMatch(List<int> matches, int? disambiguationHint) {
  if (matches.isEmpty) return null;
  if (matches.length == 1 || disambiguationHint == null) return matches.first;
  return matches.reduce(
    (a, b) => (a - disambiguationHint).abs() <= (b - disambiguationHint).abs()
        ? a
        : b,
  );
}

List<HighlightSpan> _spansFromRange(
  List<BlockProvenanceRun> pageRuns,
  List<int> blockOffsets,
  int matchStart,
  int matchEnd,
) {
  final spans = <HighlightSpan>[];
  for (final run in pageRuns) {
    final blockBase = blockOffsets[run.mergedBlockIndex];
    final runPageStart = blockBase + run.mergedStart;
    final runPageEnd = blockBase + run.mergedEnd;

    final overlapStart = runPageStart > matchStart ? runPageStart : matchStart;
    final overlapEnd = runPageEnd < matchEnd ? runPageEnd : matchEnd;
    if (overlapStart >= overlapEnd) continue;

    final originalStart = run.originalStart + (overlapStart - runPageStart);
    final originalEnd = run.originalEnd - (runPageEnd - overlapEnd);

    spans.add(
      HighlightSpan(
        originalBlockIndex: run.originalBlockIndex,
        startOffset: originalStart,
        endOffset: originalEnd,
      ),
    );
  }
  return spans;
}

List<HighlightSpan>? resolveSelectionAnchor({
  required List<String> mergedBlockTexts,
  required List<BlockProvenanceRun> pageRuns,
  required String selectedText,
  int? disambiguationHint,
}) {
  final selection = selectedText.trim();
  if (selection.isEmpty) return null;

  final blockOffsets = <int>[];
  var cumulative = 0;
  for (final text in mergedBlockTexts) {
    blockOffsets.add(cumulative);
    cumulative += text.length;
  }
  final pageText = mergedBlockTexts.join();

  final exactMatches = _findAllMatches(pageText, selection);
  final exactMatch = _pickMatch(exactMatches, disambiguationHint);
  if (exactMatch != null) {
    final spans = _spansFromRange(
      pageRuns,
      blockOffsets,
      exactMatch,
      exactMatch + selection.length,
    );
    return spans.isEmpty ? null : spans;
  }

  final collapsedPage = _collapseWhitespace(pageText);
  final collapsedSelection = _collapseWhitespace(selection).text;
  final fuzzyMatches = _findAllMatches(collapsedPage.text, collapsedSelection);
  final fuzzyMatch = _pickMatch(fuzzyMatches, disambiguationHint);
  if (fuzzyMatch == null) return null;

  final mapping = collapsedPage.toOriginal;
  final lastIndex = fuzzyMatch + collapsedSelection.length - 1;
  if (lastIndex >= mapping.length) return null;

  final originalStart = mapping[fuzzyMatch];
  final originalEnd = mapping[lastIndex] + 1;

  final spans = _spansFromRange(
    pageRuns,
    blockOffsets,
    originalStart,
    originalEnd,
  );
  return spans.isEmpty ? null : spans;
}

class MergedRange {
  const MergedRange(this.start, this.end);
  final int start;
  final int end;
}

Map<int, List<MergedRange>> mapSpansToMergedRanges({
  required List<HighlightSpan> spans,
  required List<BlockProvenanceRun> pageRuns,
}) {
  final result = <int, List<MergedRange>>{};
  for (final span in spans) {
    for (final run in pageRuns) {
      if (run.originalBlockIndex != span.originalBlockIndex) continue;

      final overlapStart = run.originalStart > span.startOffset
          ? run.originalStart
          : span.startOffset;
      final overlapEnd = run.originalEnd < span.endOffset
          ? run.originalEnd
          : span.endOffset;
      if (overlapStart >= overlapEnd) continue;

      final mergedStart = run.mergedStart + (overlapStart - run.originalStart);
      final mergedEnd = run.mergedEnd - (run.originalEnd - overlapEnd);

      result
          .putIfAbsent(run.mergedBlockIndex, () => [])
          .add(MergedRange(mergedStart, mergedEnd));
    }
  }
  return result;
}

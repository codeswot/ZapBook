import 'package:zapbook/zbf/zbf.dart';

final RegExp _pageNumberPattern = RegExp(
  r'^[\s\-–—]*(?:\d{1,4}|[ivxlcdm]{1,7}|page\s+\d{1,4})[\s\-–—.]*$',
  caseSensitive: false,
);

bool _isNoise(BookBlock block) {
  if (block is ParagraphBlock) {
    final text = block.text.trim();
    if (text.isEmpty) return true;
    if (_pageNumberPattern.hasMatch(text)) return true;
    return false;
  }
  if (block is HeadingBlock) return block.text.trim().isEmpty;
  if (block is CaptionBlock) return block.text.trim().isEmpty;
  return false;
}

bool pageHasContent(List<BookBlock> blocks) => blocks.any((b) => !_isNoise(b));

final RegExp _dotLeaderPattern = RegExp(r'[.·•‣⋯]{2,}\s*\d{0,4}\s*$');

bool _isDotLeaderLine(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return false;
  return _dotLeaderPattern.hasMatch(trimmed);
}

bool isTableOfContentsPage(List<BookBlock> blocks) {
  var count = 0;
  var leaders = 0;
  for (final block in blocks) {
    if (_isNoise(block)) continue;
    if (block is ParagraphBlock) {
      count++;
      if (_isDotLeaderLine(block.text)) leaders++;
    } else if (block is HeadingBlock) {
      count++;
      if (_isDotLeaderLine(block.text)) leaders++;
    }
  }
  if (count < 3) return false;
  return leaders / count >= 0.5;
}

List<BookBlock> mergeReadingBlocks(List<BookBlock> rawBlocks) =>
    mergeReadingBlocksWithProvenance(rawBlocks).blocks;

String blockPlainText(BookBlock block) => switch (block) {
  HeadingBlock(:final text) => text,
  ParagraphBlock(:final text) => text,
  PullquoteBlock(:final text) => text,
  CodeBlock(:final text) => text,
  CaptionBlock(:final text) => text,
  ImageBlock(:final altText) => altText,
  _ => '',
};

final class BlockProvenanceRun {
  const BlockProvenanceRun({
    required this.mergedBlockIndex,
    required this.mergedStart,
    required this.mergedEnd,
    required this.originalBlockIndex,
    required this.originalStart,
    required this.originalEnd,
  });

  final int mergedBlockIndex;
  final int mergedStart;
  final int mergedEnd;
  final int originalBlockIndex;
  final int originalStart;
  final int originalEnd;
}

final class MergeResult {
  const MergeResult(this.blocks, this.provenance);
  final List<BookBlock> blocks;
  final List<BlockProvenanceRun> provenance;
}

MergeResult mergeReadingBlocksWithProvenance(List<BookBlock> rawBlocks) {
  var maxLen = 0;
  var count = 0;
  for (final b in rawBlocks) {
    if (!_isNoise(b)) {
      count++;
      if (b is ParagraphBlock && b.text.length > maxLen) {
        maxLen = b.text.length;
      }
    }
  }

  final result = <BookBlock>[];
  final provenance = <BlockProvenanceRun>[];

  if (count < 2) {
    for (var i = 0; i < rawBlocks.length; i++) {
      if (_isNoise(rawBlocks[i])) continue;
      final length = blockPlainText(rawBlocks[i]).length;
      provenance.add(
        BlockProvenanceRun(
          mergedBlockIndex: result.length,
          mergedStart: 0,
          mergedEnd: length,
          originalBlockIndex: i,
          originalStart: 0,
          originalEnd: length,
        ),
      );
      result.add(rawBlocks[i]);
    }
    return MergeResult(
      List.unmodifiable(result),
      List.unmodifiable(provenance),
    );
  }

  final widthThreshold = maxLen == 0 ? 0 : (maxLen * 0.66).floor();

  ParagraphBlock? pending;
  var pendingRuns = <BlockProvenanceRun>[];

  void flush() {
    if (pending != null) {
      final mergedIndex = result.length;
      for (final run in pendingRuns) {
        provenance.add(
          BlockProvenanceRun(
            mergedBlockIndex: mergedIndex,
            mergedStart: run.mergedStart,
            mergedEnd: run.mergedEnd,
            originalBlockIndex: run.originalBlockIndex,
            originalStart: run.originalStart,
            originalEnd: run.originalEnd,
          ),
        );
      }
      result.add(pending!);
      pending = null;
      pendingRuns = [];
    }
  }

  List<BlockProvenanceRun> soloRun(int originalBlockIndex, ParagraphBlock b) {
    return [
      BlockProvenanceRun(
        mergedBlockIndex: -1,
        mergedStart: 0,
        mergedEnd: b.text.length,
        originalBlockIndex: originalBlockIndex,
        originalStart: 0,
        originalEnd: b.text.length,
      ),
    ];
  }

  for (var i = 0; i < rawBlocks.length; i++) {
    final block = rawBlocks[i];
    if (_isNoise(block)) continue;

    if (block is! ParagraphBlock) {
      flush();
      final length = blockPlainText(block).length;
      provenance.add(
        BlockProvenanceRun(
          mergedBlockIndex: result.length,
          mergedStart: 0,
          mergedEnd: length,
          originalBlockIndex: i,
          originalStart: 0,
          originalEnd: length,
        ),
      );
      result.add(block);
      continue;
    }

    if (pending == null) {
      pending = block;
      pendingRuns = soloRun(i, block);
      continue;
    }

    final bool noSpace;
    if (_isWordFragmentSplit(pending!, block)) {
      noSpace = true;
    } else if (_continues(pending!, widthThreshold)) {
      noSpace = false;
    } else {
      flush();
      pending = block;
      pendingRuns = soloRun(i, block);
      continue;
    }

    final aText = pending!.text.trimRight();
    final hyphenated = aText.endsWith('-');
    final keptLength = hyphenated ? aText.length - 1 : aText.length;
    final glueLength = (hyphenated || noSpace) ? 0 : 1;
    final leadingTrim = block.text.length - block.text.trimLeft().length;

    final clipped = <BlockProvenanceRun>[];
    for (final run in pendingRuns) {
      if (run.mergedStart >= keptLength) continue;
      final newEnd = run.mergedEnd > keptLength ? keptLength : run.mergedEnd;
      final delta = run.mergedEnd - newEnd;
      clipped.add(
        BlockProvenanceRun(
          mergedBlockIndex: run.mergedBlockIndex,
          mergedStart: run.mergedStart,
          mergedEnd: newEnd,
          originalBlockIndex: run.originalBlockIndex,
          originalStart: run.originalStart,
          originalEnd: run.originalEnd - delta,
        ),
      );
    }

    final newRunStart = keptLength + glueLength;
    final newRun = BlockProvenanceRun(
      mergedBlockIndex: -1,
      mergedStart: newRunStart,
      mergedEnd: newRunStart + (block.text.length - leadingTrim),
      originalBlockIndex: i,
      originalStart: leadingTrim,
      originalEnd: block.text.length,
    );

    pending = _join(pending!, block, noSpace: noSpace);
    pendingRuns = [...clipped, newRun];
  }
  flush();

  return MergeResult(List.unmodifiable(result), List.unmodifiable(provenance));
}

final RegExp _whitespace = RegExp(r'\s');

bool _isWordFragmentSplit(ParagraphBlock previous, ParagraphBlock next) {
  final prev = previous.text.trimRight();
  final cont = next.text.trim();
  if (prev.isEmpty || cont.isEmpty) return false;
  if (_whitespace.hasMatch(cont)) return false;

  final lastChar = prev.codeUnitAt(prev.length - 1);
  final isLetter =
      (lastChar >= 65 && lastChar <= 90) || (lastChar >= 97 && lastChar <= 122);
  if (!isLetter) return false;

  final firstChar = cont.codeUnitAt(0);
  final isLowerLetter = firstChar >= 97 && firstChar <= 122;
  if (!isLowerLetter) return false;

  final prevSingleToken = !_whitespace.hasMatch(prev);
  if (prevSingleToken) return true;

  return cont.length == 1 && cont != 'a' && cont != 'i';
}

bool _continues(ParagraphBlock previous, int widthThreshold) {
  final text = previous.text.trimRight();
  if (text.isEmpty) return false;
  if (_endsSentence(text)) return false;
  return previous.text.length >= widthThreshold;
}

bool _endsSentence(String text) {
  final last = text[text.length - 1];
  return _terminators.contains(last);
}

const Set<String> _terminators = {
  '.',
  '!',
  '?',
  ':',
  ';',
  '…',
  '"',
  '”',
  '’',
  ')',
  '»',
};

ParagraphBlock _join(
  ParagraphBlock a,
  ParagraphBlock b, {
  bool noSpace = false,
}) {
  final aText = a.text.trimRight();
  final hyphenated = aText.endsWith('-');
  final left = hyphenated ? aText.substring(0, aText.length - 1) : aText;
  final glue = (hyphenated || noSpace) ? '' : ' ';
  final mergedText = '$left$glue${b.text.trimLeft()}';

  final aRuns = _runsOf(a);
  final bRuns = _runsOf(b);
  List<TextRun>? mergedRuns;
  if (aRuns != null && bRuns != null) {
    mergedRuns = [
      ..._trimTrailingHyphen(aRuns, hyphenated),
      if (!hyphenated && !noSpace) const TextRun(' '),
      ...bRuns,
    ];
  }

  return ParagraphBlock(text: mergedText, runs: mergedRuns);
}

List<TextRun>? _runsOf(ParagraphBlock block) => block.runs;

List<TextRun> _trimTrailingHyphen(List<TextRun> runs, bool hyphenated) {
  if (!hyphenated || runs.isEmpty) return runs;
  final last = runs.last;
  final trimmed = last.text.replaceFirst(RegExp(r'-\s*$'), '');
  return [
    ...runs.sublist(0, runs.length - 1),
    TextRun(trimmed, bold: last.bold, italic: last.italic, code: last.code),
  ];
}

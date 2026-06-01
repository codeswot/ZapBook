import 'package:zapbook/zbf/zbf.dart';

List<BookBlock> mergeReadingBlocks(List<BookBlock> blocks) {
  if (blocks.length < 2) return List.unmodifiable(blocks);

  final maxLen = blocks.whereType<ParagraphBlock>().fold<int>(
    0,
    (m, b) => b.text.length > m ? b.text.length : m,
  );
  final widthThreshold = maxLen == 0 ? 0 : (maxLen * 0.66).floor();

  final result = <BookBlock>[];
  ParagraphBlock? pending;

  void flush() {
    if (pending != null) {
      result.add(pending!);
      pending = null;
    }
  }

  for (final block in blocks) {
    if (block is! ParagraphBlock) {
      flush();
      result.add(block);
      continue;
    }
    if (pending == null) {
      pending = block;
      continue;
    }
    if (_continues(pending!, widthThreshold)) {
      pending = _join(pending!, block);
    } else {
      flush();
      pending = block;
    }
  }
  flush();

  return List.unmodifiable(result);
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

ParagraphBlock _join(ParagraphBlock a, ParagraphBlock b) {
  final aText = a.text.trimRight();
  final hyphenated = aText.endsWith('-');
  final left = hyphenated ? aText.substring(0, aText.length - 1) : aText;
  final separator = hyphenated ? '' : ' ';
  final mergedText = '$left$separator${b.text.trimLeft()}';

  final aRuns = _runsOf(a);
  final bRuns = _runsOf(b);
  List<TextRun>? mergedRuns;
  if (aRuns != null && bRuns != null) {
    mergedRuns = [
      ..._trimTrailingHyphen(aRuns, hyphenated),
      if (!hyphenated) const TextRun(' '),
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

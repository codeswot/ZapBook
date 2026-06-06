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

List<BookBlock> _stripNoise(List<BookBlock> blocks) =>
    blocks.where((b) => !_isNoise(b)).toList();

bool pageHasContent(List<BookBlock> blocks) => _stripNoise(blocks).isNotEmpty;

final RegExp _dotLeaderPattern = RegExp(r'[.·•‣⋯]{2,}\s*\d{0,4}\s*$');

bool _isDotLeaderLine(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return false;
  return _dotLeaderPattern.hasMatch(trimmed);
}

bool isTableOfContentsPage(List<BookBlock> blocks) {
  final lines = <String>[];
  for (final block in _stripNoise(blocks)) {
    if (block is ParagraphBlock) {
      lines.add(block.text);
    } else if (block is HeadingBlock) {
      lines.add(block.text);
    }
  }
  if (lines.length < 3) return false;
  final leaders = lines.where(_isDotLeaderLine).length;
  return leaders / lines.length >= 0.5;
}

List<BookBlock> mergeReadingBlocks(List<BookBlock> rawBlocks) {
  final blocks = _stripNoise(rawBlocks);
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
    if (_isWordFragmentSplit(pending!, block)) {
      pending = _join(pending!, block, noSpace: true);
    } else if (_continues(pending!, widthThreshold)) {
      pending = _join(pending!, block);
    } else {
      flush();
      pending = block;
    }
  }
  flush();

  return List.unmodifiable(result);
}

final RegExp _whitespace = RegExp(r'\s');
final RegExp _endsLetter = RegExp(r'[A-Za-z]$');

bool _isWordFragmentSplit(ParagraphBlock previous, ParagraphBlock next) {
  final prev = previous.text.trimRight();
  final cont = next.text.trim();
  if (prev.isEmpty || cont.isEmpty) return false;
  if (_whitespace.hasMatch(cont)) return false;
  if (!_endsLetter.hasMatch(prev)) return false;
  if (!RegExp(r'^[a-z]').hasMatch(cont)) return false;

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

ParagraphBlock _join(ParagraphBlock a, ParagraphBlock b, {bool noSpace = false}) {
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

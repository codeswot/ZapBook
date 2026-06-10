import 'package:reading_progress/reading_progress.dart';

import 'package:zapbook/core/data/paragraph_merger.dart';
import 'package:zapbook/core/extensions/string_extension.dart';
import 'package:zapbook/zbf/zbf.dart';

final RegExp _whitespace = RegExp(r'\s+');

int countWords(String text) => text.wordCount;

int _blockWords(BookBlock block) {
  return switch (block) {
    ParagraphBlock(:final text) => countWords(text),
    HeadingBlock(:final text) => countWords(text),
    PullquoteBlock(:final text) => countWords(text),
    CaptionBlock(:final text) => countWords(text),
    CodeBlock(:final text) => countWords(text),
    _ => 0,
  };
}

int pageWordCount(BookPage page) =>
    page.blocks.fold(0, (sum, block) => sum + _blockWords(block));

bool isDensitySkippable(BookPage page) {
  if (page.layoutType == BookLayoutType.processing) return false;
  if (page.layoutType == BookLayoutType.illustration) return false;
  if (!pageHasContent(page.blocks)) return true;
  return isTableOfContentsPage(page.blocks);
}

Genre genreFromLabel(String? label) {
  if (label == null) return Genre.unknown;
  final value = label.toLowerCase();
  if (value.contains('fiction')) {
    return value.contains('non') ? Genre.nonFiction : Genre.fiction;
  }
  return Genre.unknown;
}

BookDensity bookDensityFromPages(List<BookPage> pages, {String? genre}) {
  final pageWords = <int>[];
  final skippable = <int>{};
  for (var index = 0; index < pages.length; index++) {
    final page = pages[index];
    pageWords.add(pageWordCount(page));
    if (isDensitySkippable(page)) skippable.add(index);
  }
  return BookDensity(
    pageWords: pageWords,
    skippablePages: skippable,
    genre: genreFromLabel(genre),
  );
}

BookDensity bookDensityFromHandle(ZbfBookHandle handle) {
  final m = handle.manifest;
  return BookDensity(
    pageWords: m.pageWords ?? [],
    skippablePages: m.skippablePages?.toSet() ?? const {},
    genre: genreFromLabel(m.genre),
  );
}

final _sentenceEnd = RegExp(r'[.!?]\s');

class _PageText {
  _PageText(this.pageIndex, this.text, this.startWord);
  final int pageIndex;
  final String text;
  final int startWord;
}

String extractMilestoneText(
  ZbfBookHandle handle,
  BookDensity density,
  int milestoneIdx, {
  int wordsPerMilestone = 900,
}) {
  final startWord = milestoneIdx * wordsPerMilestone;
  final endWord = (milestoneIdx + 1) * wordsPerMilestone;

  final pages = <_PageText>[];
  var cumulative = 0;
  for (var i = 0; i < handle.manifest.pageCount; i++) {
    final page = handle.pageAt(i);
    if (density.skippablePages.contains(i)) continue;
    final text = _pageText(page);
    if (text.isEmpty) continue;
    pages.add(_PageText(i, text, cumulative));
    final pWords = density.pageWords.length > i ? density.pageWords[i] : countWords(text);
    cumulative += pWords;
    if (cumulative >= endWord) break;
  }

  final buf = StringBuffer();
  var started = false;
  for (final p in pages) {
    final pWords = density.pageWords.length > p.pageIndex ? density.pageWords[p.pageIndex] : countWords(p.text);
    final pageEnd = p.startWord + pWords;
    if (pageEnd <= startWord) continue;
    if (p.startWord >= endWord) break;

    if (!started) {
      started = true;
      final words = p.text.split(_whitespace);
      final skipWords = startWord - p.startWord;
      var wordCount = 0;
      for (final w in words) {
        if (wordCount >= skipWords) {
          buf.write(w);
          buf.write(' ');
        }
        wordCount++;
        if (wordCount >= (endWord - p.startWord)) break;
      }
    } else {
      buf.write(p.text);
      buf.write(' ');
    }
  }

  var result = buf.toString().trimRight();
  final lastSentence = _sentenceEnd.allMatches(result).toList();
  if (lastSentence.isNotEmpty) {
    final lastMatch = lastSentence.last;
    result = result.substring(0, lastMatch.end).trimRight();
  }

  return result;
}

String _pageText(BookPage page) {
  final buf = StringBuffer();
  for (final block in page.blocks) {
    final text = _blockText(block);
    if (text.isNotEmpty) {
      buf.write(text);
      buf.write(' ');
    }
  }
  return buf.toString().trimRight();
}

String _blockText(BookBlock block) {
  return switch (block) {
    ParagraphBlock(:final text) => text,
    HeadingBlock(:final text) => text,
    PullquoteBlock(:final text) => text,
    CaptionBlock(:final text) => text,
    CodeBlock(:final text) => text,
    _ => '',
  };
}

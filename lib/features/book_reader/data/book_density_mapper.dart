import 'package:reading_progress/reading_progress.dart';

import 'package:zapbook/core/data/paragraph_merger.dart';
import 'package:zapbook/zbf/zbf.dart';

final RegExp _whitespace = RegExp(r'\s+');

int countWords(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  return trimmed.split(_whitespace).length;
}

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
  if (m.pageWords != null) {
    return BookDensity(
      pageWords: m.pageWords!,
      skippablePages: m.skippablePages?.toSet() ?? const {},
      genre: genreFromLabel(m.genre),
    );
  }
  final pages = [
    for (var index = 0; index < m.pageCount; index++)
      handle.pageAt(index),
  ];
  return bookDensityFromPages(pages, genre: m.genre);
}

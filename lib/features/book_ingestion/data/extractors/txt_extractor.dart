import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/features/book_ingestion/data/support/page_layout.dart';
import 'package:zapbook/features/book_ingestion/data/support/parsed_content.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/isolate_book_extractor.dart';

final class TxtExtractor extends IsolateBookExtractor {
  TxtExtractor({super.coverGenerator, super.assembler});

  @override
  BookSourceFormat get format => BookSourceFormat.txt;

  @override
  String get fileExtension => '.txt';

  @override
  Future<ParsedContent> parse(Uint8List bytes, String title) =>
      Isolate.run(() => _parseTxt(bytes, title));
}

final RegExp _paragraphSplit = RegExp(r'\n[ \t]*\n');
final RegExp _chapterHeading = RegExp(r'^Chapter\s+\d+', caseSensitive: false);
final RegExp _numberedHeading = RegExp(r'^\d+\.$');

ParsedContent _parseTxt(Uint8List bytes, String title) {
  final paragraphs = utf8
      .decode(bytes)
      .split(_paragraphSplit)
      .map((paragraph) => paragraph.trim())
      .where((paragraph) => paragraph.isNotEmpty);

  final builder = _ChapterBuilder(fallbackTitle: title);
  for (final paragraph in paragraphs) {
    builder.add(paragraph);
  }

  return ParsedContent(
    title: title,
    author: 'Unknown',
    needsAiProcessing: false,
    chapters: builder.build(),
  );
}

bool _isHeading(String paragraph) {
  if (paragraph.contains('\n')) {
    return false;
  }
  if (_chapterHeading.hasMatch(paragraph)) {
    return true;
  }
  if (_numberedHeading.hasMatch(paragraph)) {
    return true;
  }
  return paragraph.length < 50;
}

final class _ChapterBuilder {
  _ChapterBuilder({required this.fallbackTitle});

  final String fallbackTitle;
  final List<BookChapter> _chapters = [];
  String _currentTitle = '';
  final List<BookBlock> _blocks = [];
  int _pageNumber = 0;

  void add(String paragraph) {
    if (_isHeading(paragraph)) {
      _flush();
      _currentTitle = paragraph;
      _blocks.add(HeadingBlock(level: 1, text: paragraph));
      return;
    }
    _blocks.add(ParagraphBlock(text: paragraph));
  }

  List<BookChapter> build() {
    _flush();
    if (_chapters.isEmpty) {
      return [BookChapter(index: 0, title: fallbackTitle, pages: const [])];
    }
    return List.unmodifiable(_chapters);
  }

  void _flush() {
    if (_blocks.isEmpty) {
      return;
    }
    final index = _chapters.length;
    final title = _currentTitle.isEmpty ? fallbackTitle : _currentTitle;
    _pageNumber++;
    final blocks = List<BookBlock>.unmodifiable(_blocks);
    final page = BookPage(
      pageNumber: _pageNumber,
      chapterIndex: index,
      chapterTitle: title,
      layoutType: PageLayout.infer(blocks),
      needsAiProcessing: false,
      blocks: blocks,
    );
    _chapters.add(BookChapter(index: index, title: title, pages: [page]));
    _blocks.clear();
    _currentTitle = '';
  }
}

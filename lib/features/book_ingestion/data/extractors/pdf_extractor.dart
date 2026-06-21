import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:zapbook/core/domain/pdf_chunk_extractor.dart';
import 'package:zapbook/core/extensions/string_extension.dart';
import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/core/domain/pdf_page_rasterizer.dart';
import 'package:zapbook/features/book_ingestion/data/ai/printing_pdf_rasterizer.dart';

import 'package:zapbook/features/book_ingestion/data/support/parsed_content.dart';
import 'package:zapbook/features/book_ingestion/data/support/text_runs.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/isolate_book_extractor.dart';

final class PdfExtractor extends IsolateBookExtractor
    implements PdfChunkExtractor {
  PdfExtractor({
    super.coverGenerator,
    super.assembler,
    this.rasterizer = const PrintingPdfRasterizer(),
  });

  final PdfPageRasterizer rasterizer;

  @override
  BookSourceFormat get format => BookSourceFormat.pdf;

  @override
  String get fileExtension => '.pdf';

  @override
  Future<ParsedContent> parse(
    String filePath,
    String title,
    String bookId,
    String outputDirectory,
  ) async {
    final coverSource = await rasterizer.render(filePath, 0);
    return Isolate.run(() {
      final bytes = File(filePath).readAsBytesSync();
      return _parsePdf(bytes, title, outputDirectory, coverSource);
    });
  }

  @override
  Future<List<BookPage>> extractRange(
    String pdfFilePath,
    int startPageIndex,
    int endPageIndex,
    String chapterTitle,
    int chapterIndex,
  ) => Isolate.run(() {
    return _extractRange(
      pdfFilePath,
      startPageIndex,
      endPageIndex,
      chapterTitle,
      chapterIndex,
    );
  });

  Future<void> extractRemainingInBackground(
    String pdfFilePath,
    String outputDirectory,
    String fallbackTitle,
  ) => Isolate.run(() {
    final bytes = File(pdfFilePath).readAsBytesSync();
    _extractRemaining(bytes, fallbackTitle, outputDirectory);
  });
}

const double _headingScale = 1.25;
const int _headingMaxWords = 8;
const int _sparseTextThreshold = 40;
final RegExp _chapterHeading = RegExp(r'^Chapter\s+\d+', caseSensitive: false);
final RegExp _monospaceFont = RegExp(
  r'mono|courier|consol|menlo|monaco|inconsolata|source\s*code|fira\s*code|'
  r'roboto\s*mono|space\s*mono|jetbrains|ubuntu\s*mono|dejavu\s*sans\s*mono',
  caseSensitive: false,
);

ParsedContent _parsePdf(
  Uint8List bytes,
  String fallbackTitle,
  String outputDirectory,
  Uint8List? coverSource,
) {
  final document = PdfDocument(inputBytes: bytes);
  try {
    final extractor = PdfTextExtractor(document);
    final pageCount = document.pages.count;
    final metadata = _readMetadata(document, fallbackTitle);

    final db = sqlite3.open('$outputDirectory/pages.db');
    db.execute('PRAGMA journal_mode=WAL;');
    try {
      db.execute('''
        CREATE TABLE IF NOT EXISTS pages (
          page_index INTEGER PRIMARY KEY,
          chapter_index INTEGER,
          json TEXT
        )
      ''');

      final stmt = db.prepare(
        'INSERT INTO pages (page_index, chapter_index, json) VALUES (?, ?, ?)',
      );

      final lineCache = <int, List<TextLine>>{};
      final builder = _PdfChapterBuilder(
        fallbackTitle: metadata.title,
        stmt: stmt,
      );
      final limit = pageCount < 10 ? pageCount : 10;
      for (var index = 0; index < limit; index++) {
        final lines = extractor.extractTextLines(
          startPageIndex: index,
          endPageIndex: index,
        );
        lineCache[index] = lines;
        builder.addPage(_buildPage(extractor, index, cachedLines: lines));
      }
      if (pageCount > limit) {
        for (var index = limit; index < pageCount; index++) {
          builder.addPlaceholderPage(index + 1);
        }
      }

      final pageWords = <int>[];
      final skippable = <int>[];
      for (var i = 0; i < pageCount; i++) {
        if (i < limit) {
          final lines =
              lineCache[i] ??
              extractor.extractTextLines(startPageIndex: i, endPageIndex: i);
          var wordCount = 0;
          for (final line in lines) {
            wordCount += line.text.wordCount;
          }
          pageWords.add(wordCount);
          if (wordCount == 0) {
            skippable.add(i);
          }
        } else {
          pageWords.add(100); // Placeholder word count for background pages
        }
      }

      return ParsedContent(
        title: metadata.title,
        author: metadata.author,
        needsAiProcessing: builder.needsAiProcessing,
        chapters: builder.build(),
        coverSource: coverSource,
        pageWords: pageWords,
        skippablePages: skippable,
        assets: coverSource != null ? {'page_1.png': coverSource} : const {},
      );
    } finally {
      db.close();
    }
  } finally {
    document.dispose();
  }
}

List<BookPage> _extractRange(
  String pdfFilePath,
  int startPageIndex,
  int endPageIndex,
  String chapterTitle,
  int chapterIndex,
) {
  final bytes = File(pdfFilePath).readAsBytesSync();
  final document = PdfDocument(inputBytes: bytes);
  try {
    final extractor = PdfTextExtractor(document);
    final pageCount = document.pages.count;
    final pages = <BookPage>[];
    final end = endPageIndex >= pageCount ? pageCount - 1 : endPageIndex;
    for (var index = startPageIndex; index <= end; index++) {
      final draft = _buildPage(extractor, index);
      pages.add(
        BookPage(
          pageNumber: index + 1,
          chapterIndex: chapterIndex,
          chapterTitle: chapterTitle,
          layoutType: draft.layoutType,
          needsAiProcessing: draft.needsAiProcessing,
          blocks: List.unmodifiable(draft.blocks),
        ),
      );
    }
    return pages;
  } finally {
    document.dispose();
  }
}

void _extractRemaining(
  Uint8List bytes,
  String fallbackTitle,
  String outputDirectory,
) {
  final document = PdfDocument(inputBytes: bytes);
  try {
    final extractor = PdfTextExtractor(document);
    final pageCount = document.pages.count;
    final limit = pageCount < 10 ? pageCount : 10;
    if (pageCount <= limit) return;

    final metadata = _readMetadata(document, fallbackTitle);

    final db = sqlite3.open('$outputDirectory/pages.db');
    db.execute('PRAGMA journal_mode=WAL;');
    try {
      final stmt = db.prepare(
        'INSERT OR REPLACE INTO pages (page_index, chapter_index, json) VALUES (?, ?, ?)',
      );

      for (var index = limit; index < pageCount; index++) {
        final draft = _buildPage(extractor, index);
        final page = BookPage(
          pageNumber: index + 1,
          chapterIndex: 0,
          chapterTitle: metadata.title,
          layoutType: draft.layoutType,
          needsAiProcessing: draft.needsAiProcessing,
          blocks: List.unmodifiable(draft.blocks),
        );
        stmt.execute([index, 0, jsonEncode(page.toJson())]);
      }
    } finally {
      db.close();
    }
  } finally {
    document.dispose();
  }
}

_PdfPageDraft _buildPage(
  PdfTextExtractor extractor,
  int index, {
  List<TextLine>? cachedLines,
}) {
  final lines =
      cachedLines ??
      extractor.extractTextLines(startPageIndex: index, endPageIndex: index);
  final bodySize = _dominantFontSize(lines);
  final blocks = <BookBlock>[];
  final codeLines = <String>[];
  var characters = 0;

  void flushCode() {
    if (codeLines.isNotEmpty) {
      blocks.add(CodeBlock(text: codeLines.join('\n')));
      codeLines.clear();
    }
  }

  for (final line in lines) {
    final raw = line.text;
    final text = raw.trim();
    if (text.isEmpty) {
      if (codeLines.isNotEmpty) {
        codeLines.add('');
      }
      continue;
    }
    characters += text.length;
    if (_isMonospace(line)) {
      codeLines.add(raw.replaceFirst(RegExp(r'\s+$'), ''));
      continue;
    }
    flushCode();
    if (_isHeading(line, text, bodySize)) {
      blocks.add(HeadingBlock(level: 1, text: text));
    } else {
      blocks.add(ParagraphBlock(text: text, runs: _lineRuns(line)));
    }
  }
  flushCode();

  if (index == 0) {
    blocks.insert(0, const ImageBlock(assetRef: 'page_1.png'));
  }

  final sparse = characters < _sparseTextThreshold;
  final opensChapter = blocks.isNotEmpty && blocks.first is HeadingBlock;
  return _PdfPageDraft(
    blocks: blocks,
    opensChapter: opensChapter,
    needsAiProcessing: sparse,
    layoutType: _layoutFor(opensChapter: opensChapter, sparse: sparse),
  );
}

List<TextRun>? _lineRuns(TextLine line) {
  final words = line.wordCollection;
  if (words.isEmpty) {
    return null;
  }
  final runs = <TextRun>[];
  for (var index = 0; index < words.length; index++) {
    final word = words[index];
    final suffix = index == words.length - 1 ? '' : ' ';
    runs.add(
      TextRun(
        word.text + suffix,
        bold: word.fontStyle.contains(PdfFontStyle.bold),
        italic: word.fontStyle.contains(PdfFontStyle.italic),
        code: _monospaceFont.hasMatch(word.fontName),
      ),
    );
  }
  return styledRunsOrNull(runs);
}

bool _isMonospace(TextLine line) {
  final lineFont = line.fontName;
  final font = lineFont.isNotEmpty
      ? lineFont
      : (line.wordCollection.isEmpty ? '' : line.wordCollection.first.fontName);
  return _monospaceFont.hasMatch(font);
}

BookLayoutType _layoutFor({required bool opensChapter, required bool sparse}) {
  if (opensChapter) {
    return BookLayoutType.chapterOpener;
  }
  if (sparse) {
    return BookLayoutType.illustration;
  }
  return BookLayoutType.textHeavy;
}

bool _isHeading(TextLine line, String text, double bodySize) {
  if (_chapterHeading.hasMatch(text)) {
    return true;
  }
  final wordCount = line.wordCollection.length;
  if (wordCount == 0 || wordCount > _headingMaxWords) {
    return false;
  }
  return line.fontSize >= bodySize * _headingScale;
}

double _dominantFontSize(List<TextLine> lines) {
  final frequency = <int, int>{};
  for (final line in lines) {
    final rounded = line.fontSize.round();
    if (rounded <= 0) {
      continue;
    }
    frequency[rounded] = (frequency[rounded] ?? 0) + 1;
  }
  if (frequency.isEmpty) {
    return 12;
  }
  var dominant = 12;
  var best = -1;
  frequency.forEach((size, count) {
    if (count > best) {
      best = count;
      dominant = size;
    }
  });
  return dominant.toDouble();
}

_PdfMetadata _readMetadata(PdfDocument document, String fallbackTitle) {
  final information = document.documentInformation;
  final title = information.title.trim();
  final author = information.author.trim();
  return _PdfMetadata(
    title: title.isEmpty ? fallbackTitle : title,
    author: author.isEmpty ? 'Unknown' : author,
  );
}

final class _PdfPageDraft {
  const _PdfPageDraft({
    required this.blocks,
    required this.opensChapter,
    required this.needsAiProcessing,
    required this.layoutType,
  });

  final List<BookBlock> blocks;
  final bool opensChapter;
  final bool needsAiProcessing;
  final BookLayoutType layoutType;
}

final class _PdfMetadata {
  const _PdfMetadata({required this.title, required this.author});

  final String title;
  final String author;
}

final class _PdfChapterBuilder {
  _PdfChapterBuilder({required this.fallbackTitle, required this.stmt});

  final String fallbackTitle;
  final PreparedStatement stmt;
  final List<ChapterSummary> _chapters = [];
  int _chapterPageCount = 0;
  String _currentTitle = '';
  int _chapterIndex = -1;
  int _pageNumber = 0;
  bool needsAiProcessing = false;

  void addPage(_PdfPageDraft draft) {
    needsAiProcessing = needsAiProcessing || draft.needsAiProcessing;
    if (_chapterIndex == -1 || draft.opensChapter) {
      _flush();
      _chapterIndex = _chapters.length;
      _currentTitle = _titleFor(draft);
    }
    _pageNumber++;
    _chapterPageCount++;
    final page = BookPage(
      pageNumber: _pageNumber,
      chapterIndex: _chapterIndex,
      chapterTitle: _currentTitle,
      layoutType: draft.layoutType,
      needsAiProcessing: draft.needsAiProcessing,
      blocks: List.unmodifiable(draft.blocks),
    );
    stmt.execute([_pageNumber - 1, _chapterIndex, jsonEncode(page.toJson())]);
  }

  void addPlaceholderPage(int pageNumber) {
    if (_chapterIndex == -1) {
      _flush();
      _chapterIndex = 0;
      _currentTitle = fallbackTitle;
    }
    _pageNumber++;
    _chapterPageCount++;
    final page = BookPage(
      pageNumber: pageNumber,
      chapterIndex: _chapterIndex,
      chapterTitle: _currentTitle,
      layoutType: BookLayoutType.processing,
      needsAiProcessing: false,
      blocks: const [],
    );
    stmt.execute([pageNumber - 1, _chapterIndex, jsonEncode(page.toJson())]);
  }

  String _titleFor(_PdfPageDraft draft) {
    for (final block in draft.blocks) {
      if (block is HeadingBlock) {
        return block.text;
      }
    }
    return 'Chapter ${_chapters.length + 1}';
  }

  List<ChapterSummary> build() {
    _flush();
    if (_chapters.isEmpty) {
      return [
        ChapterSummary(
          index: 0,
          title: fallbackTitle,
          pageCount: _chapterPageCount,
        ),
      ];
    }
    return List.unmodifiable(_chapters);
  }

  void _flush() {
    if (_chapterPageCount == 0) {
      return;
    }
    _chapters.add(
      ChapterSummary(
        index: _chapterIndex,
        title: _currentTitle.isEmpty ? fallbackTitle : _currentTitle,
        pageCount: _chapterPageCount,
      ),
    );
    _chapterPageCount = 0;
  }
}

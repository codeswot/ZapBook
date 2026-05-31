import 'dart:isolate';
import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/features/book_ingestion/data/support/parsed_content.dart';
import 'package:zapbook/features/book_ingestion/data/support/text_runs.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/isolate_book_extractor.dart';

final class PdfExtractor extends IsolateBookExtractor {
  PdfExtractor({super.coverGenerator, super.assembler});

  @override
  BookSourceFormat get format => BookSourceFormat.pdf;

  @override
  String get fileExtension => '.pdf';

  @override
  Future<ParsedContent> parse(Uint8List bytes, String title) =>
      Isolate.run(() => _parsePdf(bytes, title));
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

ParsedContent _parsePdf(Uint8List bytes, String fallbackTitle) {
  final document = PdfDocument(inputBytes: bytes);
  try {
    final extractor = PdfTextExtractor(document);
    final pageCount = document.pages.count;
    final metadata = _readMetadata(document, fallbackTitle);

    final builder = _PdfChapterBuilder(fallbackTitle: metadata.title);
    for (var index = 0; index < pageCount; index++) {
      builder.addPage(_buildPage(extractor, index));
    }

    return ParsedContent(
      title: metadata.title,
      author: metadata.author,
      needsAiProcessing: builder.needsAiProcessing,
      chapters: builder.build(),
    );
  } finally {
    document.dispose();
  }
}

_PdfPageDraft _buildPage(PdfTextExtractor extractor, int index) {
  final lines = extractor.extractTextLines(
    startPageIndex: index,
    endPageIndex: index,
  );
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
  _PdfChapterBuilder({required this.fallbackTitle});

  final String fallbackTitle;
  final List<BookChapter> _chapters = [];
  List<BookPage> _pages = [];
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
    _pages.add(
      BookPage(
        pageNumber: _pageNumber,
        chapterIndex: _chapterIndex,
        chapterTitle: _currentTitle,
        layoutType: draft.layoutType,
        needsAiProcessing: draft.needsAiProcessing,
        blocks: List.unmodifiable(draft.blocks),
      ),
    );
  }

  String _titleFor(_PdfPageDraft draft) {
    for (final block in draft.blocks) {
      if (block is HeadingBlock) {
        return block.text;
      }
    }
    return 'Chapter ${_chapters.length + 1}';
  }

  List<BookChapter> build() {
    _flush();
    if (_chapters.isEmpty) {
      return [BookChapter(index: 0, title: fallbackTitle, pages: const [])];
    }
    return List.unmodifiable(_chapters);
  }

  void _flush() {
    if (_pages.isEmpty) {
      return;
    }
    _chapters.add(
      BookChapter(
        index: _chapterIndex,
        title: _currentTitle.isEmpty ? fallbackTitle : _currentTitle,
        pages: List.unmodifiable(_pages),
      ),
    );
    _pages = [];
  }
}

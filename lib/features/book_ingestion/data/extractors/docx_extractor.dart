import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/features/book_ingestion/data/support/archive_support.dart';
import 'package:zapbook/features/book_ingestion/data/support/page_layout.dart';
import 'package:zapbook/features/book_ingestion/data/support/parsed_content.dart';
import 'package:zapbook/features/book_ingestion/data/support/text_runs.dart';
import 'package:zapbook/features/book_ingestion/data/support/xml_support.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/isolate_book_extractor.dart';

final class DocxExtractor extends IsolateBookExtractor {
  DocxExtractor({super.coverGenerator, super.assembler});

  @override
  BookSourceFormat get format => BookSourceFormat.docx;

  @override
  String get fileExtension => '.docx';

  @override
  Future<ParsedContent> parse(Uint8List bytes, String title) =>
      Isolate.run(() => _parseDocx(bytes, title));
}

final RegExp _headingStyle = RegExp(r'^Heading([1-9])$', caseSensitive: false);
const Set<String> _pullquoteStyles = {
  'quote',
  'blocktext',
  'blockquote',
  'intensequote',
};

ParsedContent _parseDocx(Uint8List bytes, String fallbackTitle) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final documentXml = archive.textFile('word/document.xml');
  if (documentXml == null) {
    throw const FormatException('DOCX is missing word/document.xml');
  }

  final relationships = _parseRelationships(archive);
  final media = _collectMedia(archive, relationships);
  final metadata = _parseMetadata(archive, fallbackTitle);

  final document = XmlDocument.parse(documentXml);
  final paragraphs = document
      .descendantsByLocalName('body')
      .expand((body) => body.descendantsByLocalName('p'));

  final builder = _DocxChapterBuilder(fallbackTitle: metadata.title);
  for (final paragraph in paragraphs) {
    _consumeParagraph(paragraph, media.assetByRelationship, builder);
  }

  return ParsedContent(
    title: metadata.title,
    author: metadata.author,
    needsAiProcessing: false,
    chapters: builder.build(),
    assets: media.assets,
    coverSource: media.firstImage,
  );
}

void _consumeParagraph(
  XmlElement paragraph,
  Map<String, String> assetByRelationship,
  _DocxChapterBuilder builder,
) {
  final style =
      paragraph
          .firstDescendantByLocalName('pStyle')
          ?.attributeByLocalName('val') ??
      'Normal';
  final text = paragraph
      .descendantsByLocalName('t')
      .map((node) => node.innerText)
      .join();
  final runs = _paragraphRuns(paragraph);
  final headingMatch = _headingStyle.firstMatch(style);

  if (headingMatch != null && text.trim().isNotEmpty) {
    final level = int.parse(headingMatch.group(1) ?? '1');
    builder.addHeading(level: level, text: text.trim(), runs: runs);
  } else if (_pullquoteStyles.contains(style.toLowerCase()) &&
      text.trim().isNotEmpty) {
    builder.addBlock(PullquoteBlock(text: text.trim(), runs: runs));
  } else if (text.trim().isNotEmpty) {
    builder.addBlock(ParagraphBlock(text: text.trim(), runs: runs));
  }

  for (final blip in paragraph.descendantsByLocalName('blip')) {
    final embed = blip.attributeByLocalName('embed');
    final assetRef = embed == null ? null : assetByRelationship[embed];
    if (assetRef != null) {
      final altText =
          paragraph
              .firstDescendantByLocalName('docPr')
              ?.attributeByLocalName('descr') ??
          '';
      builder.addBlock(ImageBlock(assetRef: assetRef, altText: altText));
    }
  }
}

List<TextRun>? _paragraphRuns(XmlElement paragraph) {
  final runs = <TextRun>[];
  for (final run in paragraph.descendantsByLocalName('r')) {
    final text = run
        .descendantsByLocalName('t')
        .map((node) => node.innerText)
        .join();
    if (text.isEmpty) {
      continue;
    }
    final properties = run.firstDescendantByLocalName('rPr');
    runs.add(
      TextRun(
        text,
        bold: _hasToggle(properties, 'b'),
        italic: _hasToggle(properties, 'i'),
      ),
    );
  }
  return styledRunsOrNull(runs);
}

bool _hasToggle(XmlElement? properties, String localName) {
  if (properties == null) {
    return false;
  }
  final matches = properties.childrenByLocalName(localName);
  if (matches.isEmpty) {
    return false;
  }
  final value = matches.first.attributeByLocalName('val');
  return value == null || !{'false', '0', 'off'}.contains(value.toLowerCase());
}

Map<String, String> _parseRelationships(Archive archive) {
  final relsXml = archive.textFile('word/_rels/document.xml.rels');
  if (relsXml == null) {
    return const {};
  }
  final result = <String, String>{};
  for (final relationship in XmlDocument.parse(
    relsXml,
  ).descendantsByLocalName('Relationship')) {
    final id = relationship.attributeByLocalName('Id');
    final target = relationship.attributeByLocalName('Target');
    if (id != null && target != null) {
      result[id] = _resolveTarget(target);
    }
  }
  return result;
}

String _resolveTarget(String target) {
  final normalised = target.replaceAll('\\', '/');
  if (normalised.startsWith('/')) {
    return normalised.substring(1);
  }
  if (normalised.startsWith('word/')) {
    return normalised;
  }
  return 'word/$normalised';
}

_DocxMedia _collectMedia(Archive archive, Map<String, String> relationships) {
  final mediaFiles =
      archive.files
          .where((file) => file.name.startsWith('word/media/'))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  final assets = <String, Uint8List>{};
  final assetByPath = <String, String>{};
  Uint8List? firstImage;
  var index = 1;
  for (final file in mediaFiles) {
    final extension = _extension(file.name);
    final assetName = AssetNaming.imageAsset(index, extension);
    final bytes = file.content;
    assets[assetName] = bytes;
    assetByPath[file.name] = assetName;
    firstImage ??= bytes;
    index++;
  }

  final assetByRelationship = <String, String>{};
  relationships.forEach((relationshipId, path) {
    final assetName = assetByPath[path];
    if (assetName != null) {
      assetByRelationship[relationshipId] = assetName;
    }
  });

  return _DocxMedia(
    assets: assets,
    assetByRelationship: assetByRelationship,
    firstImage: firstImage,
  );
}

_DocxMetadata _parseMetadata(Archive archive, String fallbackTitle) {
  final coreXml = archive.textFile('docProps/core.xml');
  if (coreXml == null) {
    return _DocxMetadata(title: fallbackTitle, author: 'Unknown');
  }
  final document = XmlDocument.parse(coreXml);
  final title = document.firstDescendantByLocalName('title')?.innerText.trim();
  final author = document
      .firstDescendantByLocalName('creator')
      ?.innerText
      .trim();
  return _DocxMetadata(
    title: (title == null || title.isEmpty) ? fallbackTitle : title,
    author: (author == null || author.isEmpty) ? 'Unknown' : author,
  );
}

String _extension(String path) {
  final dot = path.lastIndexOf('.');
  if (dot == -1 || dot == path.length - 1) {
    return 'png';
  }
  return path.substring(dot + 1).toLowerCase();
}

final class _DocxMedia {
  const _DocxMedia({
    required this.assets,
    required this.assetByRelationship,
    required this.firstImage,
  });

  final Map<String, Uint8List> assets;
  final Map<String, String> assetByRelationship;
  final Uint8List? firstImage;
}

final class _DocxMetadata {
  const _DocxMetadata({required this.title, required this.author});

  final String title;
  final String author;
}

final class _DocxChapterBuilder {
  _DocxChapterBuilder({required this.fallbackTitle});

  final String fallbackTitle;
  final List<BookChapter> _chapters = [];
  final List<BookBlock> _blocks = [];
  String _currentTitle = '';
  int _pageNumber = 0;

  void addHeading({
    required int level,
    required String text,
    List<TextRun>? runs,
  }) {
    if (level == 1) {
      _flush();
      _currentTitle = text;
    }
    _blocks.add(HeadingBlock(level: level, text: text, runs: runs));
  }

  void addBlock(BookBlock block) => _blocks.add(block);

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

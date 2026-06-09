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

final class EpubExtractor extends IsolateBookExtractor {
  EpubExtractor({super.coverGenerator, super.assembler});

  @override
  BookSourceFormat get format => BookSourceFormat.epub;

  @override
  String get fileExtension => '.epub';

  @override
  Future<ParsedContent> parse(Uint8List bytes, String title) =>
      Isolate.run(() => _parseEpub(bytes, title));
}

ParsedContent _parseEpub(Uint8List bytes, String fallbackTitle) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final opfPath = _locateOpf(archive);
  if (opfPath == null) {
    throw const FormatException('EPUB is missing content.opf');
  }
  final opfXml = archive.textFile(opfPath);
  if (opfXml == null) {
    throw const FormatException('EPUB content.opf is unreadable');
  }

  final opfDir = _directoryOf(opfPath);
  final package = _Package.parse(XmlDocument.parse(opfXml), opfDir);

  final assetRegistry = _AssetRegistry();
  final chapters = <BookChapter>[];
  for (var index = 0; index < package.spine.length; index++) {
    final chapter = _parseChapter(
      archive,
      package.spine[index],
      index,
      assetRegistry,
    );
    if (chapter != null) {
      chapters.add(chapter);
    }
  }

  final coverHref = package.coverHref;
  final coverSource = coverHref == null ? null : archive.binaryFile(coverHref);

  final pageWords = <int>[];
  final skippable = <int>[];
  for (final chapter in chapters) {
    for (final page in chapter.pages) {
      var words = 0;
      for (final block in page.blocks) {
        final text = switch (block) {
          ParagraphBlock(:final text) => text,
          HeadingBlock(:final text) => text,
          PullquoteBlock(:final text) => text,
          CaptionBlock(:final text) => text,
          CodeBlock(:final text) => text,
          _ => '',
        };
        words += text
            .trim()
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .length;
      }
      pageWords.add(words);
      if (words == 0) skippable.add(pageWords.length - 1);
    }
  }

  return ParsedContent(
    title: package.title.isEmpty ? fallbackTitle : package.title,
    author: package.author,
    needsAiProcessing: false,
    chapters: chapters,
    assets: assetRegistry.assets,
    coverSource: coverSource,
    pageWords: pageWords,
    skippablePages: skippable,
  );
}

BookChapter? _parseChapter(
  Archive archive,
  String href,
  int index,
  _AssetRegistry assetRegistry,
) {
  final xhtml = archive.textFile(href);
  if (xhtml == null) {
    return null;
  }
  final document = XmlDocument.parse(xhtml);
  final body = document.firstDescendantByLocalName('body');
  if (body == null) {
    return null;
  }
  final chapterDir = _directoryOf(href);
  final blocks = <BookBlock>[];
  for (final node in body.childElements) {
    _walk(node, chapterDir, archive, assetRegistry, blocks);
  }
  final title = _titleOf(blocks, index);
  final page = BookPage(
    pageNumber: index + 1,
    chapterIndex: index,
    chapterTitle: title,
    layoutType: PageLayout.infer(blocks),
    needsAiProcessing: false,
    blocks: List.unmodifiable(blocks),
  );
  return BookChapter(index: index, title: title, pages: [page]);
}

void _walk(
  XmlElement element,
  String chapterDir,
  Archive archive,
  _AssetRegistry assetRegistry,
  List<BookBlock> blocks,
) {
  switch (element.name.local.toLowerCase()) {
    case 'h1':
      _addHeading(element, 1, blocks);
    case 'h2':
      _addHeading(element, 2, blocks);
    case 'h3':
      _addHeading(element, 3, blocks);
    case 'p':
      _addParagraph(element, chapterDir, archive, assetRegistry, blocks);
    case 'blockquote':
      _addPullquote(element, blocks);
    case 'pre':
      _addCode(element, blocks);
    case 'img':
      _addImage(element, chapterDir, archive, assetRegistry, blocks);
    case 'figcaption':
      _addCaption(element, blocks);
    case 'hr':
      blocks.add(const DividerBlock());
    default:
      for (final child in element.childElements) {
        _walk(child, chapterDir, archive, assetRegistry, blocks);
      }
  }
}

void _addHeading(XmlElement element, int level, List<BookBlock> blocks) {
  final text = element.innerText.trim();
  if (text.isNotEmpty) {
    blocks.add(
      HeadingBlock(level: level, text: text, runs: _richRuns(element)),
    );
  }
}

void _addParagraph(
  XmlElement element,
  String chapterDir,
  Archive archive,
  _AssetRegistry assetRegistry,
  List<BookBlock> blocks,
) {
  final text = element.innerText.trim();
  if (text.isNotEmpty) {
    blocks.add(ParagraphBlock(text: text, runs: _richRuns(element)));
  }
  for (final image in element.descendantsByLocalName('img')) {
    _addImage(image, chapterDir, archive, assetRegistry, blocks);
  }
}

void _addPullquote(XmlElement element, List<BookBlock> blocks) {
  final text = element.innerText.trim();
  if (text.isNotEmpty) {
    blocks.add(PullquoteBlock(text: text, runs: _richRuns(element)));
  }
}

List<TextRun>? _richRuns(XmlElement element) {
  return styledRunsOrNull(
    _collectRuns(element, bold: false, italic: false, code: false),
  );
}

List<TextRun> _collectRuns(
  XmlNode node, {
  required bool bold,
  required bool italic,
  required bool code,
}) {
  final runs = <TextRun>[];
  for (final child in node.children) {
    if (child is XmlText || child is XmlCDATA) {
      final value = child.value ?? '';
      if (value.isNotEmpty) {
        runs.add(TextRun(value, bold: bold, italic: italic, code: code));
      }
    } else if (child is XmlElement) {
      final name = child.name.local.toLowerCase();
      runs.addAll(
        _collectRuns(
          child,
          bold: bold || name == 'strong' || name == 'b',
          italic: italic || name == 'em' || name == 'i',
          code: code || name == 'code',
        ),
      );
    }
  }
  return runs;
}

void _addCode(XmlElement element, List<BookBlock> blocks) {
  final text = element.innerText.replaceFirst(RegExp(r'\s+$'), '');
  if (text.isEmpty) {
    return;
  }
  blocks.add(CodeBlock(text: text, language: _codeLanguage(element)));
}

String? _codeLanguage(XmlElement element) {
  final code = element.firstDescendantByLocalName('code') ?? element;
  final className = code.attributeByLocalName('class') ?? '';
  final match = RegExp(r'language-([\w+-]+)').firstMatch(className);
  return match?.group(1);
}

void _addCaption(XmlElement element, List<BookBlock> blocks) {
  final text = element.innerText.trim();
  if (text.isNotEmpty) {
    blocks.add(CaptionBlock(text: text));
  }
}

void _addImage(
  XmlElement element,
  String chapterDir,
  Archive archive,
  _AssetRegistry assetRegistry,
  List<BookBlock> blocks,
) {
  final src = element.attributeByLocalName('src');
  if (src == null || src.isEmpty) {
    return;
  }
  final path = _resolvePath(chapterDir, src);
  final bytes = archive.binaryFile(path);
  if (bytes == null) {
    return;
  }
  final assetRef = assetRegistry.register(path, bytes, _extension(path));
  final altText = element.attributeByLocalName('alt') ?? '';
  blocks.add(ImageBlock(assetRef: assetRef, altText: altText));
}

String _titleOf(List<BookBlock> blocks, int index) {
  for (final block in blocks) {
    if (block is HeadingBlock) {
      return block.text;
    }
  }
  return 'Chapter ${index + 1}';
}

String? _locateOpf(Archive archive) {
  final containerXml = archive.textFile('META-INF/container.xml');
  if (containerXml == null) {
    return null;
  }
  final rootfile = XmlDocument.parse(
    containerXml,
  ).firstDescendantByLocalName('rootfile');
  return rootfile?.attributeByLocalName('full-path');
}

String _directoryOf(String path) {
  final slash = path.lastIndexOf('/');
  return slash == -1 ? '' : path.substring(0, slash);
}

String _resolvePath(String baseDir, String relative) {
  final cleanRelative = relative.split('#').first.split('?').first;
  final segments = <String>[
    if (baseDir.isNotEmpty) ...baseDir.split('/'),
    ...cleanRelative.split('/'),
  ];
  final resolved = <String>[];
  for (final segment in segments) {
    if (segment.isEmpty || segment == '.') {
      continue;
    }
    if (segment == '..') {
      if (resolved.isNotEmpty) {
        resolved.removeLast();
      }
      continue;
    }
    resolved.add(segment);
  }
  return resolved.join('/');
}

String _extension(String path) {
  final dot = path.lastIndexOf('.');
  if (dot == -1 || dot == path.length - 1) {
    return 'png';
  }
  return path.substring(dot + 1).toLowerCase();
}

final class _AssetRegistry {
  final Map<String, Uint8List> assets = {};
  final Map<String, String> _byPath = {};
  int _counter = 0;

  String register(String path, Uint8List bytes, String extension) {
    final existing = _byPath[path];
    if (existing != null) {
      return existing;
    }
    _counter++;
    final assetName = AssetNaming.imageAsset(_counter, extension);
    _byPath[path] = assetName;
    assets[assetName] = bytes;
    return assetName;
  }
}

final class _Package {
  const _Package({
    required this.title,
    required this.author,
    required this.spine,
    required this.coverHref,
  });

  final String title;
  final String author;
  final List<String> spine;
  final String? coverHref;

  factory _Package.parse(XmlDocument document, String opfDir) {
    final manifest = <String, _ManifestItem>{};
    for (final item in document.descendantsByLocalName('item')) {
      final id = item.attributeByLocalName('id');
      final href = item.attributeByLocalName('href');
      if (id == null || href == null) {
        continue;
      }
      manifest[id] = _ManifestItem(
        href: _join(opfDir, href),
        properties: item.attributeByLocalName('properties') ?? '',
      );
    }

    final spine = <String>[];
    for (final itemref in document.descendantsByLocalName('itemref')) {
      final idref = itemref.attributeByLocalName('idref');
      final item = idref == null ? null : manifest[idref];
      if (item != null) {
        spine.add(item.href);
      }
    }

    final title =
        document.firstDescendantByLocalName('title')?.innerText.trim() ?? '';
    final author =
        document.firstDescendantByLocalName('creator')?.innerText.trim() ?? '';

    return _Package(
      title: title.isEmpty ? 'Untitled' : title,
      author: author.isEmpty ? 'Unknown' : author,
      spine: spine,
      coverHref: _coverHref(document, manifest),
    );
  }

  static String? _coverHref(
    XmlDocument document,
    Map<String, _ManifestItem> manifest,
  ) {
    for (final item in manifest.values) {
      if (item.properties.contains('cover-image')) {
        return item.href;
      }
    }
    for (final meta in document.descendantsByLocalName('meta')) {
      if (meta.attributeByLocalName('name') == 'cover') {
        final content = meta.attributeByLocalName('content');
        final item = content == null ? null : manifest[content];
        if (item != null) {
          return item.href;
        }
      }
    }
    return null;
  }

  static String _join(String dir, String href) {
    if (dir.isEmpty) {
      return href;
    }
    return '$dir/$href';
  }
}

final class _ManifestItem {
  const _ManifestItem({required this.href, required this.properties});

  final String href;
  final String properties;
}

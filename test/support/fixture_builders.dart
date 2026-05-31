import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:archive/archive.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

const String sampleTxt = '''
Chapter 1

It was the best of times, it was the worst of times, it was the age of wisdom.

The road stretched on for many miles beneath the pale and watchful moon.

Chapter 2

A new dawn broke over the silent hills and the travelers pressed onward.
''';

final Uint8List _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

Uint8List buildDocxBytes() {
  final archive = Archive()
    ..addFile(_file('[Content_Types].xml', _docxContentTypes))
    ..addFile(_file('_rels/.rels', _docxRootRels))
    ..addFile(_file('word/document.xml', _docxDocument))
    ..addFile(_file('word/_rels/document.xml.rels', _docxDocumentRels))
    ..addFile(_file('docProps/core.xml', _docxCore))
    ..addBinary('word/media/image1.png', _onePixelPng);
  return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
}

Uint8List buildEpubBytes() {
  final archive = Archive()
    ..addFile(_file('mimetype', 'application/epub+zip'))
    ..addFile(_file('META-INF/container.xml', _epubContainer))
    ..addFile(_file('OEBPS/content.opf', _epubOpf))
    ..addFile(_file('OEBPS/ch1.xhtml', _epubChapterOne))
    ..addFile(_file('OEBPS/ch2.xhtml', _epubChapterTwo))
    ..addBinary('OEBPS/images/cover.png', _onePixelPng)
    ..addBinary('OEBPS/images/pic1.png', _onePixelPng);
  return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
}

Future<Uint8List> buildPdfBytes() async {
  final document = PdfDocument();
  document.documentInformation.title = 'Sample PDF Book';
  document.documentInformation.author = 'Ada Lovelace';

  final heading = PdfStandardFont(PdfFontFamily.helvetica, 28);
  final body = PdfStandardFont(PdfFontFamily.helvetica, 12);

  _drawPage(document, heading, body, 'Chapter 1', [
    'The engine hummed through the long quiet night of computation.',
    'Numbers turned into music as the cards clicked into place.',
  ]);
  _drawPage(document, heading, body, null, [
    'The work continued across many pages of careful reasoning.',
    'Each result confirmed the patient design of the machine.',
  ]);
  _drawPage(document, heading, body, 'Chapter 2', [
    'A second movement began, bolder than the first.',
    'The notes of logic rose into a deliberate and certain theme.',
  ]);
  _drawCodePage(document, PdfStandardFont(PdfFontFamily.courier, 11), const [
    'fn main() {',
    '    let answer = 42;',
    '    println!("{answer}");',
    '}',
  ]);

  final bytes = await document.save();
  document.dispose();
  return Uint8List.fromList(bytes);
}

void _drawPage(
  PdfDocument document,
  PdfFont heading,
  PdfFont body,
  String? title,
  List<String> paragraphs,
) {
  final page = document.pages.add();
  final graphics = page.graphics;
  var top = 40.0;
  if (title != null) {
    graphics.drawString(
      title,
      heading,
      bounds: Rect.fromLTWH(40, top, 500, 40),
    );
    top += 60;
  }
  for (final paragraph in paragraphs) {
    graphics.drawString(
      paragraph,
      body,
      bounds: Rect.fromLTWH(40, top, 500, 40),
    );
    top += 40;
  }
}

void _drawCodePage(PdfDocument document, PdfFont monoFont, List<String> lines) {
  final graphics = document.pages.add().graphics;
  var top = 40.0;
  for (final line in lines) {
    graphics.drawString(
      line,
      monoFont,
      bounds: Rect.fromLTWH(40, top, 500, 20),
    );
    top += 20;
  }
}

ArchiveFile _file(String name, String content) {
  final bytes = utf8.encode(content);
  return ArchiveFile(name, bytes.length, bytes);
}

extension on Archive {
  void addBinary(String name, Uint8List bytes) {
    addFile(ArchiveFile(name, bytes.length, bytes));
  }
}

const String _docxContentTypes =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
    '<Default Extension="png" ContentType="image/png"/>'
    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
    '<Default Extension="xml" ContentType="application/xml"/>'
    '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
    '</Types>';

const String _docxRootRels =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
    '</Relationships>';

const String _docxDocument =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<w:document '
    'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
    'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
    'xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture" '
    'xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing">'
    '<w:body>'
    '<w:p><w:pPr><w:pStyle w:val="Heading1"/></w:pPr><w:r><w:t>The Beginning</w:t></w:r></w:p>'
    '<w:p><w:r><w:t>It was a </w:t></w:r>'
    '<w:r><w:rPr><w:b/></w:rPr><w:t>dark</w:t></w:r>'
    '<w:r><w:t> and stormy night in the old town.</w:t></w:r></w:p>'
    '<w:p><w:pPr><w:pStyle w:val="Quote"/></w:pPr><w:r><w:t>He who reads, leads.</w:t></w:r></w:p>'
    '<w:p><w:r><w:drawing><wp:inline><wp:docPr id="1" name="pic" descr="A quiet forest"/>'
    '<a:graphic><a:graphicData><pic:pic><pic:blipFill><a:blip r:embed="rId1"/></pic:blipFill></pic:pic>'
    '</a:graphicData></a:graphic></wp:inline></w:drawing></w:r></w:p>'
    '<w:p><w:pPr><w:pStyle w:val="Heading1"/></w:pPr><w:r><w:t>The Middle</w:t></w:r></w:p>'
    '<w:p><w:r><w:t>The journey continued for many long and weary miles.</w:t></w:r></w:p>'
    '</w:body></w:document>';

const String _docxDocumentRels =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/image1.png"/>'
    '</Relationships>';

const String _docxCore =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<cp:coreProperties '
    'xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" '
    'xmlns:dc="http://purl.org/dc/elements/1.1/">'
    '<dc:title>Sample DOCX Book</dc:title>'
    '<dc:creator>Jane Author</dc:creator>'
    '</cp:coreProperties>';

const String _epubContainer =
    '<?xml version="1.0"?>'
    '<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">'
    '<rootfiles>'
    '<rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>'
    '</rootfiles></container>';

const String _epubOpf =
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="bookid">'
    '<metadata xmlns:dc="http://purl.org/dc/elements/1.1/">'
    '<dc:title>Sample EPUB Book</dc:title>'
    '<dc:creator>John Writer</dc:creator>'
    '<meta name="cover" content="cover-img"/>'
    '</metadata>'
    '<manifest>'
    '<item id="cover-img" href="images/cover.png" media-type="image/png" properties="cover-image"/>'
    '<item id="pic1" href="images/pic1.png" media-type="image/png"/>'
    '<item id="ch1" href="ch1.xhtml" media-type="application/xhtml+xml"/>'
    '<item id="ch2" href="ch2.xhtml" media-type="application/xhtml+xml"/>'
    '</manifest>'
    '<spine>'
    '<itemref idref="ch1"/>'
    '<itemref idref="ch2"/>'
    '</spine></package>';

const String _epubChapterOne =
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<html xmlns="http://www.w3.org/1999/xhtml"><head><title>Chapter 1</title></head>'
    '<body>'
    '<h1>The Forest</h1>'
    '<p>Once upon a <strong>deep</strong> and <em>ancient</em> '
    '<code>wood</code>.</p>'
    '<blockquote>Nature is the truest book of all.</blockquote>'
    '<figure><img src="images/pic1.png" alt="A tall tree"/>'
    '<figcaption>Figure 1: A tall tree</figcaption></figure>'
    '<hr/>'
    '</body></html>';

const String _epubChapterTwo =
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<html xmlns="http://www.w3.org/1999/xhtml"><head><title>Chapter 2</title></head>'
    '<body>'
    '<h2>The River</h2>'
    '<p>Water flowed gently over the smooth grey stones.</p>'
    '<pre><code class="language-dart">void main() {\n  print(42);\n}</code></pre>'
    '</body></html>';

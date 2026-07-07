import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/epub_extractor.dart';
import 'package:zapbook/zbf/zbf.dart';

void main() {
  late EpubExtractor extractor;
  late String tempDirPath;
  late String testEpubPath;

  setUpAll(() {
    final tempDir = Directory.systemTemp.createTempSync('epub_extractor_test');
    tempDirPath = tempDir.path;
    testEpubPath = '$tempDirPath/test.epub';

    final archive = Archive();
    archive.addFile(
      ArchiveFile('mimetype', 20, utf8.encode('application/epub+zip')),
    );

    final containerXml = '''
<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
    archive.addFile(
      ArchiveFile(
        'META-INF/container.xml',
        containerXml.length,
        utf8.encode(containerXml),
      ),
    );

    final contentOpf = '''
<?xml version="1.0"?>
<package version="3.0" xmlns="http://www.idpf.org/2007/opf">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>Test Epub</dc:title>
    <dc:creator>Test Author</dc:creator>
  </metadata>
  <manifest>
    <item id="item1" href="chapter1.html" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="item1"/>
  </spine>
</package>''';
    archive.addFile(
      ArchiveFile('content.opf', contentOpf.length, utf8.encode(contentOpf)),
    );

    final chapter1 = '''
<html xmlns="http://www.w3.org/1999/xhtml">
  <head><title>Chapter 1</title></head>
  <body>
    <h1>Chapter 1</h1>
    <p>Hello world.</p>
  </body>
</html>''';
    archive.addFile(
      ArchiveFile('chapter1.html', chapter1.length, utf8.encode(chapter1)),
    );

    final bytes = ZipEncoder().encode(archive);
    File(testEpubPath).writeAsBytesSync(bytes);
  });

  tearDownAll(() {
    Directory(tempDirPath).deleteSync(recursive: true);
  });

  setUp(() {
    extractor = EpubExtractor();
  });

  test('properties', () {
    expect(extractor.format, BookSourceFormat.epub);
    expect(extractor.fileExtension, '.epub');
  });

  test('parse returns parsed content', () async {
    final result = await extractor.parse(
      testEpubPath,
      'Fallback Title',
      'circle_id',
      tempDirPath,
    );
    expect(result.title, 'Test Epub');
    expect(result.author, 'Test Author');
  });
}

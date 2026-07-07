import 'dart:io';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/pdf_extractor.dart';
import 'package:zapbook/zbf/zbf.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/domain/pdf_page_rasterizer.dart';

class MockPdfPageRasterizer extends Mock implements PdfPageRasterizer {}

void main() {
  late PdfExtractor extractor;
  late MockPdfPageRasterizer rasterizer;
  late String tempDirPath;
  late String testPdfPath;

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('pdf_extractor_test');
    tempDirPath = tempDir.path;
    testPdfPath = '$tempDirPath/test.pdf';

    final PdfDocument document = PdfDocument();
    document.documentInformation.title = 'Real Title';
    document.documentInformation.author = 'Author';

    final PdfPage page1 = document.pages.add();
    final PdfFont fontHeading = PdfStandardFont(PdfFontFamily.helvetica, 24);
    final PdfFont fontBody = PdfStandardFont(PdfFontFamily.helvetica, 12);
    final PdfFont fontMonospace = PdfStandardFont(PdfFontFamily.courier, 12);

    page1.graphics.drawString(
      'Chapter 1',
      fontHeading,
      bounds: const Rect.fromLTWH(0, 0, 500, 50),
    );
    page1.graphics.drawString(
      'This is some regular body text for the paragraph.',
      fontBody,
      bounds: const Rect.fromLTWH(0, 50, 500, 50),
    );

    final PdfPage page2 = document.pages.add();
    page2.graphics.drawString(
      'print("hello world");',
      fontMonospace,
      bounds: const Rect.fromLTWH(0, 0, 500, 50),
    );
    page2.graphics.drawString(
      'More text.',
      fontBody,
      bounds: const Rect.fromLTWH(0, 50, 500, 50),
    );

    document.pages.add();

    File(testPdfPath).writeAsBytesSync(await document.save());
    document.dispose();
  });

  tearDownAll(() {
    Directory(tempDirPath).deleteSync(recursive: true);
  });

  setUp(() {
    rasterizer = MockPdfPageRasterizer();
    extractor = PdfExtractor(rasterizer: rasterizer);
    when(() => rasterizer.render(any(), any())).thenAnswer((_) async => null);
  });

  test('properties', () {
    expect(extractor.format, BookSourceFormat.pdf);
    expect(extractor.fileExtension, '.pdf');
  });

  test('parse extracts text, metadata, and handles pages correctly', () async {
    final result = await extractor.parse(
      testPdfPath,
      'Fallback Title',
      'circle_id',
      tempDirPath,
    );
    expect(result.title, 'Real Title');
    expect(result.author, 'Author');
    expect(result.chapters.length, 1);
    expect(result.chapters.first.title, 'Chapter 1');
    expect(result.pageWords!.length, 3);
  });

  test('extractRange extracts specific pages', () async {
    final pages = await extractor.extractRange(
      testPdfPath,
      0,
      1,
      'Chapter 1',
      0,
    );
    expect(pages.length, 2);
    expect(pages[0].pageNumber, 1);
    expect(pages[1].pageNumber, 2);
  });

  test('extractRemainingInBackground extracts pages beyond limit', () async {
    final longPdfPath = '$tempDirPath/long.pdf';
    final PdfDocument doc = PdfDocument();
    for (var i = 0; i < 12; i++) {
      doc.pages.add().graphics.drawString(
        'Page $i text',
        PdfStandardFont(PdfFontFamily.helvetica, 12),
      );
    }
    File(longPdfPath).writeAsBytesSync(await doc.save());
    doc.dispose();

    await extractor.extractRemainingInBackground(
      longPdfPath,
      tempDirPath,
      'Fallback',
    );
  });
}

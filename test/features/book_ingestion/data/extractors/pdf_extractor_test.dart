import 'dart:io';
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

    // Create a dummy PDF
    final PdfDocument document = PdfDocument();
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

  test('parse returns parsed content', () async {
    final result = await extractor.parse(
      testPdfPath,
      'Test Title',
      'circle_id',
      tempDirPath,
    );
    expect(result.title, 'Test Title');
  });
}

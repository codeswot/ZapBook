import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/txt_extractor.dart';
import 'package:zapbook/features/library/presentation/widgets/zbf_book_view.dart';
import 'package:zapbook/features/book_ingestion/domain/ai/pdf_page_rasterizer.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/zbf/zbf.dart';

import '../../../../support/fake_cover_generator.dart';
import '../../../../support/fixture_builders.dart';
import '../../../../support/temp_files.dart';

class _FakeRasterizer implements PdfPageRasterizer {
  @override
  Future<Uint8List?> render(
    Uint8List pdfBytes,
    int pageIndex, {
    double dpi = 150,
  }) async =>
      null;
}

void main() {
  late ZbfBookHandle handle;

  setUp(() async {
    final extractor = TxtExtractor(coverGenerator: const FakeCoverGenerator());
    final file = await writeTempFixture('sample.txt', utf8.encode(sampleTxt));
    final book = (await extractor.extract(file).toList()).last.result!;
    final directory = await createTempDirectory();
    final path = await const ZbfWriter().write(book, directory);
    handle = await const ZbfReader().open(path);
  });

  Future<void> pumpView(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          body: ZbfBookView(
            handle: handle,
            rasterizer: _FakeRasterizer(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the first page with its progress footer', (tester) async {
    await pumpView(tester);

    expect(find.textContaining('best of times'), findsOneWidget);
    expect(find.text('Page 1 of 2'), findsOneWidget);
  });

  testWidgets('swiping advances to the next page', (tester) async {
    await pumpView(tester);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.textContaining('A new dawn'), findsOneWidget);
    expect(find.text('Page 2 of 2'), findsOneWidget);
  });
}

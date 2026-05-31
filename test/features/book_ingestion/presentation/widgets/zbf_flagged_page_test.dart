import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/features/book_ingestion/domain/ai/pdf_page_rasterizer.dart';
import 'package:zapbook/features/book_ingestion/domain/ai/zb_inference_service.dart';
import 'package:zapbook/features/book_ingestion/domain/usecases/refine_page.dart';
import 'package:zapbook/features/book_ingestion/presentation/widgets/zbf_book_view.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/zbf/zbf.dart';

import '../../../../support/temp_files.dart';

class _FakeRasterizer implements PdfPageRasterizer {
  @override
  Future<Uint8List?> render(
    Uint8List pdfBytes,
    int pageIndex, {
    double dpi = 150,
  }) async => Uint8List.fromList([7, 7]);
}

class _FakeInference implements ZbInferenceService {
  @override
  Future<bool> isReady() async => true;
  @override
  Future<void> warmUp() async {}
  @override
  Future<ZbPageRefinement> refine(ZbPageRequest request) async =>
      const ZbPageRefinement(blocks: [ParagraphBlock(text: 'Refined by Zb')]);
  @override
  Future<void> dispose() async {}
}

Future<ZbfBookHandle> _flaggedHandle() async {
  const page = BookPage(
    pageNumber: 1,
    chapterIndex: 0,
    chapterTitle: 'One',
    layoutType: BookLayoutType.illustration,
    needsAiProcessing: true,
    blocks: [ParagraphBlock(text: 'sparse draft')],
  );
  final book = const ZbfAssembler().assemble(
    title: 'Doc',
    author: 'A',
    sourceFormat: BookSourceFormat.pdf,
    chapters: const [
      BookChapter(index: 0, title: 'One', pages: [page]),
    ],
    assets: {
      AssetNaming.sourceDocument: Uint8List.fromList([1, 2, 3]),
    },
    cover: Uint8List.fromList([0]),
    needsAiProcessing: true,
  );
  final directory = await createTempDirectory();
  final path = await const ZbfWriter().write(book, directory);
  return const ZbfReader().open(path);
}

void main() {
  testWidgets('flagged page shows Zb shimmer then swaps in refined blocks', (
    tester,
  ) async {
    final handle = await _flaggedHandle();

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          body: ZbfBookView(
            handle: handle,
            refiner: RefinePage(_FakeRasterizer(), _FakeInference()),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Zb is at it…'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Refined by Zb'), findsOneWidget);
    expect(find.text('sparse draft'), findsNothing);
  });
}

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/features/book_ingestion/domain/ai/pdf_page_rasterizer.dart';
import 'package:zapbook/features/book_ingestion/domain/ai/zb_inference_service.dart';
import 'package:zapbook/features/book_ingestion/domain/usecases/refine_page.dart';
import 'package:zapbook/zbf/zbf.dart';

class _FakeRasterizer implements PdfPageRasterizer {
  _FakeRasterizer(this.output);

  final Uint8List? output;

  @override
  Future<Uint8List?> render(
    Uint8List pdfBytes,
    int pageIndex, {
    double dpi = 150,
  }) async => output;
}

class _FakeInference implements ZbInferenceService {
  _FakeInference({this.ready = true, this.blocks = const []});

  final bool ready;
  final List<BookBlock> blocks;

  @override
  Future<bool> isReady() async => ready;

  @override
  Future<void> warmUp() async {}

  @override
  Future<ZbPageRefinement> refine(ZbPageRequest request) async =>
      ZbPageRefinement(blocks: blocks);

  @override
  Future<void> dispose() async {}
}

void main() {
  final source = Uint8List.fromList([1, 2, 3]);
  final pageImage = Uint8List.fromList([9, 9]);
  const page = BookPage(
    pageNumber: 3,
    chapterIndex: 0,
    chapterTitle: 'Two',
    layoutType: BookLayoutType.illustration,
    needsAiProcessing: true,
    blocks: [ParagraphBlock(text: 'draft')],
  );

  Future<RefinementResult?> run(PdfPageRasterizer r, ZbInferenceService i) {
    return RefinePage(
      r,
      i,
    ).call(sourcePdf: source, page: page, availableAssetRefs: const []);
  }

  test('returns refined blocks when Zb is ready and rasterizes', () async {
    final result = await run(
      _FakeRasterizer(pageImage),
      _FakeInference(blocks: const [HeadingBlock(level: 1, text: 'Real')]),
    );

    expect(result!.blocks, hasLength(1));
    expect(result.blocks.first, isA<HeadingBlock>());
    expect(result.imageBytes, equals(pageImage));
  });

  test('returns null when Zb is not ready', () async {
    final result = await run(
      _FakeRasterizer(pageImage),
      _FakeInference(ready: false),
    );
    expect(result, isNull);
  });

  test('returns null when rasterization fails', () async {
    final result = await run(_FakeRasterizer(null), _FakeInference());
    expect(result, isNull);
  });

  test('returns null when refinement is empty (keeps draft)', () async {
    final result = await run(_FakeRasterizer(pageImage), _FakeInference());
    expect(result, isNull);
  });
}

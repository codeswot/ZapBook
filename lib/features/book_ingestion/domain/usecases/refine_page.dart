import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/features/book_ingestion/domain/ai/pdf_page_rasterizer.dart';
import 'package:zapbook/features/book_ingestion/domain/ai/zb_inference_service.dart';

@injectable
final class RefinePage {
  const RefinePage(this._rasterizer, this._inference);

  final PdfPageRasterizer _rasterizer;
  final ZbInferenceService _inference;

  /// Returns Zb-refined blocks for a flagged page, or null when refinement is
  /// unavailable or produced nothing — in which case the caller keeps the draft.
  Future<List<BookBlock>?> call({
    required Uint8List sourcePdf,
    required BookPage page,
    required List<String> availableAssetRefs,
  }) async {
    if (!await _inference.isReady()) {
      return null;
    }
    final image = await _rasterizer.render(sourcePdf, page.pageNumber - 1) ?? Uint8List(0);
    final refinement = await _inference.refine(
      ZbPageRequest(
        pageNumber: page.pageNumber,
        pageImage: image,
        draftBlocks: page.blocks,
        availableAssetRefs: availableAssetRefs,
      ),
    );
    return refinement.blocks.isEmpty ? null : refinement.blocks;
  }
}

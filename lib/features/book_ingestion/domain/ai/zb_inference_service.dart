import 'dart:typed_data';

import 'package:zapbook/zbf/zbf.dart';

final class ZbPageRequest {
  const ZbPageRequest({
    required this.pageNumber,
    required this.pageImage,
    required this.draftBlocks,
    required this.availableAssetRefs,
  });

  final int pageNumber;
  final Uint8List pageImage;
  final List<BookBlock> draftBlocks;
  final List<String> availableAssetRefs;
}

final class ZbPageRefinement {
  const ZbPageRefinement({required this.blocks});

  final List<BookBlock> blocks;
}

abstract interface class ZbInferenceService {
  Future<bool> isReady();

  Future<void> warmUp();

  Future<ZbPageRefinement> refine(ZbPageRequest request);

  Future<void> dispose();
}

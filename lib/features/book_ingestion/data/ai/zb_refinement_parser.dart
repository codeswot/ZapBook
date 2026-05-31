import 'dart:convert';

import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/features/book_ingestion/domain/ai/zb_inference_service.dart';

final class ZbRefinementParser {
  const ZbRefinementParser();

  ZbPageRefinement parse(String raw, {required List<String> allowedAssetRefs}) {
    final object = _extractObject(raw);
    final rawBlocks = object?['blocks'];
    if (rawBlocks is! List) {
      return const ZbPageRefinement(blocks: []);
    }

    final allowed = allowedAssetRefs.toSet();
    final blocks = <BookBlock>[];
    for (final entry in rawBlocks) {
      if (entry is! Map) {
        continue;
      }
      final block = _blockFrom(Map<String, Object?>.from(entry), allowed);
      if (block != null) {
        blocks.add(block);
      }
    }
    return ZbPageRefinement(blocks: blocks);
  }

  BookBlock? _blockFrom(Map<String, Object?> json, Set<String> allowed) {
    if (json['type'] == 'image' && !allowed.contains(json['assetRef'])) {
      return null;
    }
    try {
      return BookBlock.fromJson(json);
    } on Object {
      return null;
    }
  }

  Map<String, Object?>? _extractObject(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end <= start) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw.substring(start, end + 1));
      return decoded is Map ? Map<String, Object?>.from(decoded) : null;
    } on FormatException {
      return null;
    }
  }
}

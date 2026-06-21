import 'dart:typed_data';

import 'package:zapbook/zbf/entities/book_manifest.dart';
import 'package:zapbook/zbf/entities/chapter_summary.dart';
import 'package:zapbook/zbf/entities/zbf_book.dart';
import 'package:zapbook/zbf/enums/book_source_format.dart';
import 'package:zapbook/zbf/support/asset_naming.dart';

final class ZbfAssembler {
  const ZbfAssembler();

  ZbfBook assemble({
    required String id,
    required String title,
    required String author,
    String? genre,
    required BookSourceFormat sourceFormat,
    required List<ChapterSummary> chapters,
    required Map<String, Uint8List> assets,
    required Uint8List cover,
    required bool needsAiProcessing,
    List<int>? pageWords,
    List<int>? skippablePages,
  }) {
    final pageCount = chapters.fold<int>(
      0,
      (sum, chapter) => sum + chapter.pageCount,
    );
    final manifest = BookManifest(
      id: id,
      title: title,
      author: author,
      genre: genre,
      sourceFormat: sourceFormat,
      pageCount: pageCount,
      chapterCount: chapters.length,
      coverAsset: AssetNaming.coverAsset,
      createdAt: DateTime.now().toUtc(),
      needsAiProcessing: needsAiProcessing,
      chapters: chapters,
      pageWords: pageWords,
      skippablePages: skippablePages,
    );
    final fullAssets = <String, Uint8List>{
      ...assets,
      AssetNaming.coverAsset: cover,
    };
    return ZbfBook(manifest: manifest, assets: fullAssets);
  }
}

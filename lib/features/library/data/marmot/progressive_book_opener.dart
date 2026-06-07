import 'package:archive/archive.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/domain/book_segment_source.dart';
import 'package:zapbook/features/library/data/marmot/book_group_datasource.dart';
import 'package:zapbook/zbf/zbf.dart';

class ProgressiveBook {
  const ProgressiveBook({required this.handle, required this.loader});

  final ZbfBookHandle handle;
  final BookSegmentLoader loader;
}

@lazySingleton
class ProgressiveBookOpener {
  ProgressiveBookOpener(this._datasource);

  final BookGroupDatasource _datasource;

  Future<ProgressiveBook?> open(String bookId) async {
    final meta = await _datasource.currentMeta(bookId);
    if (meta == null || meta.pageCount <= 0) return null;

    final manifest = BookManifest(
      id: meta.bookId,
      title: meta.title,
      author: meta.author,
      genre: meta.genre,
      sourceFormat: BookSourceFormat.fromWire(meta.sourceFormat),
      pageCount: meta.pageCount,
      chapterCount: meta.chapterCount,
      coverAsset: AssetNaming.coverAsset,
      createdAt: DateTime.fromMillisecondsSinceEpoch(meta.createdAtMs),
      needsAiProcessing: false,
      zbfVersion: meta.zbfVersion,
    );

    final handle = ZbfBookHandle(archive: Archive(), manifest: manifest);
    for (var i = 0; i < meta.pageCount; i++) {
      handle.updatePage(
        i,
        BookPage(
          pageNumber: i + 1,
          chapterIndex: 0,
          chapterTitle: '',
          layoutType: BookLayoutType.processing,
          needsAiProcessing: false,
          blocks: const [],
        ),
      );
    }

    return ProgressiveBook(
      handle: handle,
      loader: (pageIndex) => _datasource.loadSegment(
        bookId,
        pageIndex ~/ ZbfSegmenter.pagesPerSegment,
      ),
    );
  }
}

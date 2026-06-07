import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'package:zapbook/zbf/entities/book_block.dart';
import 'package:zapbook/zbf/entities/book_chapter.dart';
import 'package:zapbook/zbf/entities/book_manifest.dart';
import 'package:zapbook/zbf/entities/book_page.dart';
import 'package:zapbook/zbf/entities/zbf_book.dart';
import 'package:zapbook/zbf/support/asset_naming.dart';
import 'package:zapbook/zbf/zbf_reader.dart';
import 'package:zapbook/zbf/zbf_writer.dart';

class SegmentBlob {
  const SegmentBlob({
    required this.index,
    required this.pageStart,
    required this.pageEnd,
    required this.bytes,
  });

  final int index;
  final int pageStart;
  final int pageEnd;
  final Uint8List bytes;
}

class ParsedSegment {
  const ParsedSegment({required this.pages, required this.assets});

  final List<BookPage> pages;
  final Map<String, Uint8List> assets;
}

class ZbfSegmenter {
  const ZbfSegmenter({this.writer = const ZbfWriter()});

  final ZbfWriter writer;

  static const int pagesPerSegment = 20;

  ParsedSegment parseSegment(Uint8List zip) {
    final archive = ZipDecoder().decodeBytes(zip);
    final pages = <BookPage>[];
    final pagesFile = archive.findFile('pages.json');
    if (pagesFile != null) {
      final decoded = jsonDecode(utf8.decode(pagesFile.content)) as List;
      for (final page in decoded) {
        pages.add(BookPage.fromJson(page as Map<String, Object?>));
      }
    }
    final assets = <String, Uint8List>{};
    for (final file in archive.files) {
      if (file.name.startsWith('assets/')) {
        assets[file.name.substring('assets/'.length)] =
            Uint8List.fromList(file.content);
      }
    }
    return ParsedSegment(pages: pages, assets: assets);
  }

  static int segmentCountFor(int pageCount) =>
      pageCount <= 0 ? 0 : ((pageCount - 1) ~/ pagesPerSegment) + 1;

  List<SegmentBlob> segment(ZbfBookHandle handle) {
    final manifest = handle.manifest;
    final manifestBytes = _json(manifest.toJson());
    final total = manifest.pageCount;
    final blobs = <SegmentBlob>[];

    for (var start = 0; start < total; start += pagesPerSegment) {
      final end = min(start + pagesPerSegment, total) - 1;
      final archive = Archive()
        ..addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

      final pagesJson = <Object?>[];
      final assetRefs = <String>{};
      for (var i = start; i <= end; i++) {
        final page = handle.pageAt(i);
        pagesJson.add(page.toJson());
        for (final block in page.blocks) {
          if (block is ImageBlock) assetRefs.add(block.assetRef);
        }
      }

      final pagesBytes = _json(pagesJson);
      archive.addFile(ArchiveFile('pages.json', pagesBytes.length, pagesBytes));

      for (final ref in assetRefs) {
        final bytes = handle.asset(ref);
        if (bytes != null) {
          archive.addFile(ArchiveFile('assets/$ref', bytes.length, bytes));
        }
      }

      blobs.add(
        SegmentBlob(
          index: start ~/ pagesPerSegment,
          pageStart: start,
          pageEnd: end,
          bytes: Uint8List.fromList(ZipEncoder().encodeBytes(archive)),
        ),
      );
    }
    return blobs;
  }

  Uint8List reassemble(
    List<Uint8List> segmentZips, {
    Uint8List? coverBytes,
    Uint8List? sourceBytes,
  }) {
    BookManifest? manifest;
    final pages = <BookPage>[];
    final assets = <String, Uint8List>{};

    for (final zip in segmentZips) {
      final archive = ZipDecoder().decodeBytes(zip);
      final manifestFile = archive.findFile('manifest.json');
      if (manifest == null && manifestFile != null) {
        manifest = BookManifest.fromJson(
          jsonDecode(utf8.decode(manifestFile.content)) as Map<String, Object?>,
        );
      }
      final pagesFile = archive.findFile('pages.json');
      if (pagesFile != null) {
        final decoded = jsonDecode(utf8.decode(pagesFile.content)) as List;
        for (final page in decoded) {
          pages.add(BookPage.fromJson(page as Map<String, Object?>));
        }
      }
      for (final file in archive.files) {
        if (file.name.startsWith('assets/')) {
          assets[file.name.substring('assets/'.length)] =
              Uint8List.fromList(file.content);
        }
      }
    }

    if (manifest == null) {
      throw StateError('No manifest found in segments');
    }
    if (coverBytes != null) {
      assets[manifest.coverAsset] = coverBytes;
    }
    if (sourceBytes != null) {
      assets[AssetNaming.sourceDocument] = sourceBytes;
    }

    pages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
    final byChapter = <int, List<BookPage>>{};
    for (final page in pages) {
      (byChapter[page.chapterIndex] ??= []).add(page);
    }
    final chapters = byChapter.entries
        .map((entry) => BookChapter(
              index: entry.key,
              title: entry.value.isEmpty ? '' : entry.value.first.chapterTitle,
              pages: entry.value,
            ))
        .toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return writer.encode(
      ZbfBook(manifest: manifest, chapters: chapters, assets: assets),
    );
  }

  Uint8List _json(Object? value) =>
      Uint8List.fromList(utf8.encode(jsonEncode(value)));
}

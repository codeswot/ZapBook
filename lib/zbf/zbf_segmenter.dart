import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'dart:isolate';

import 'package:archive/archive_io.dart';

import 'package:zapbook/zbf/entities/book_block.dart';
import 'package:zapbook/zbf/entities/book_chapter.dart';
import 'package:zapbook/zbf/entities/book_manifest.dart';
import 'package:zapbook/zbf/entities/book_page.dart';
import 'package:zapbook/zbf/support/asset_naming.dart';
import 'package:zapbook/zbf/zbf_reader.dart';
import 'package:sqlite3/sqlite3.dart';

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

class _PageRow {
  const _PageRow(this.pageIndex, this.chapterIndex, this.json);
  final int pageIndex;
  final int chapterIndex;
  final String json;
}

class _DirectoryReassembleResult {
  const _DirectoryReassembleResult(
    this.manifest,
    this.pages,
    this.writtenAssets,
  );
  final BookManifest? manifest;
  final List<_PageRow> pages;
  final Set<String> writtenAssets;
}

class _AssetFile {
  const _AssetFile(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

class _FileReassembleResult {
  const _FileReassembleResult(this.manifest, this.pages, this.assets);
  final BookManifest? manifest;
  final List<BookPage> pages;
  final List<_AssetFile> assets;
}

class ZbfSegmenter {
  const ZbfSegmenter();

  static const int pagesPerSegment = 20;

  static const int _maxAssetBytes = 100 * 1024 * 1024;

  static bool _isSafeAssetName(String name) =>
      name.isNotEmpty &&
      !name.contains('..') &&
      !name.contains('/') &&
      !name.contains('\\');

  static final Converter<List<int>, Object?> _jsonUtf8 = utf8.decoder.fuse(
    const JsonDecoder(),
  );

  Future<ParsedSegment> parseSegmentAsync(Uint8List zip) async {
    return Isolate.run(() => const ZbfSegmenter()._parseSegmentSync(zip));
  }

  ParsedSegment _parseSegmentSync(Uint8List zip) {
    final archive = ZipDecoder().decodeBytes(zip);
    final pages = _pagesFrom(archive);
    final assets = <String, Uint8List>{};
    for (final file in archive.files) {
      if (!file.name.startsWith('assets/')) continue;
      final name = file.name.substring('assets/'.length);
      if (!_isSafeAssetName(name)) continue;
      assets[name] = Uint8List.fromList(file.content as List<int>);
    }
    return ParsedSegment(pages: pages, assets: assets);
  }

  static int segmentCountFor(int pageCount) =>
      pageCount <= 0 ? 0 : ((pageCount - 1) ~/ pagesPerSegment) + 1;

  Stream<SegmentBlob> segment(ZbfBookHandle handle) async* {
    final manifest = handle.manifest;
    final manifestBytes = _json(manifest.toJson());
    final total = manifest.pageCount;

    for (var start = 0; start < total; start += pagesPerSegment) {
      final end = min(start + pagesPerSegment, total) - 1;
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

      final assetData = <String, Uint8List>{};
      for (final ref in assetRefs) {
        final bytes = handle.assetNamed(ref);
        if (bytes != null) {
          assetData[ref] = bytes;
        }
      }

      final zipBytes = await Isolate.run(() {
        final archive = Archive()
          ..addFile(
            ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
          )
          ..addFile(ArchiveFile('pages.json', pagesBytes.length, pagesBytes));

        for (final entry in assetData.entries) {
          archive.addFile(
            ArchiveFile('assets/${entry.key}', entry.value.length, entry.value),
          );
        }

        return ZipEncoder().encodeBytes(archive);
      });

      yield SegmentBlob(
        index: start ~/ pagesPerSegment,
        pageStart: start,
        pageEnd: end,
        bytes: Uint8List.fromList(zipBytes),
      );
    }
  }

  Future<void> reassembleToFile(
    Stream<Uint8List> segmentZips,
    String outputPath, {
    Uint8List? coverBytes,
    Uint8List? sourceBytes,
  }) async {
    final tmpPath = '$outputPath.part';
    final encoder = ZipFileEncoder()..create(tmpPath);
    var closed = false;
    try {
      BookManifest? manifest;
      final pages = <BookPage>[];
      final writtenAssets = <String>{};

      await for (final zip in segmentZips) {
        final result = await Isolate.run(
          () => _reassembleToFileIsolate({
            'zip': zip,
            'writtenAssets': writtenAssets,
            'hasCoverBytes': coverBytes != null,
            'hasSourceBytes': sourceBytes != null,
          }),
        );

        manifest ??= result.manifest;
        pages.addAll(result.pages);

        for (final asset in result.assets) {
          writtenAssets.add(asset.name.replaceFirst('assets/', ''));
          encoder.addArchiveFile(
            ArchiveFile(asset.name, asset.bytes.length, asset.bytes),
          );
        }
      }

      if (manifest == null) {
        throw StateError('No manifest found in segments');
      }

      final manifestBytes = _json(manifest.toJson());
      encoder.addArchiveFile(
        ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
      );

      pages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
      for (final chapter in _chaptersFrom(pages)) {
        final name = 'chapters/${AssetNaming.chapterFile(chapter.index)}';
        final bytes = _json(chapter.toJson());
        encoder.addArchiveFile(ArchiveFile(name, bytes.length, bytes));
      }

      if (coverBytes != null) {
        encoder.addArchiveFile(
          ArchiveFile(manifest.coverAsset, coverBytes.length, coverBytes),
        );
      }
      if (sourceBytes != null) {
        encoder.addArchiveFile(
          ArchiveFile(
            AssetNaming.originalDocument('.${manifest.sourceFormat.wireValue}'),
            sourceBytes.length,
            sourceBytes,
          ),
        );
      }

      await encoder.close();
      closed = true;
      await File(tmpPath).rename(outputPath);
    } finally {
      if (!closed) {
        await encoder.close().catchError((Object _) {});
      }
      final tmp = File(tmpPath);
      if (tmp.existsSync()) await tmp.delete();
    }
  }

  static _FileReassembleResult _reassembleToFileIsolate(
    Map<String, dynamic> args,
  ) {
    final zip = args['zip'] as Uint8List;
    final alreadyWrittenAssets = args['writtenAssets'] as Set<String>;
    final hasCoverBytes = args['hasCoverBytes'] as bool;
    final hasSourceBytes = args['hasSourceBytes'] as bool;

    final archive = ZipDecoder().decodeBytes(zip);
    BookManifest? manifest;
    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile != null) {
      manifest = BookManifest.fromJson(
        _jsonUtf8.convert(manifestFile.content as List<int>)
            as Map<String, Object?>,
      );
    }

    final pages = <BookPage>[];
    final pagesFile = archive.findFile('pages.json');
    if (pagesFile != null) {
      final decoded = _jsonUtf8.convert(pagesFile.content as List<int>) as List;
      for (final p in decoded) {
        pages.add(BookPage.fromJson(p as Map<String, Object?>));
      }
    }

    final assets = <_AssetFile>[];
    for (final file in archive.files) {
      if (!file.name.startsWith('assets/')) continue;
      final name = file.name.substring('assets/'.length);
      if (!_isSafeAssetName(name)) continue;
      if (file.size > _maxAssetBytes) {
        throw StateError('Segment asset ${file.name} exceeds size limit');
      }
      if (alreadyWrittenAssets.contains(name)) continue;

      if (hasCoverBytes && name == manifest?.coverAsset) continue;
      if (hasSourceBytes &&
          manifest != null &&
          name ==
              AssetNaming.originalDocument(
                '.${manifest.sourceFormat.wireValue}',
              )) {
        continue;
      }

      final isRoot =
          name == manifest?.coverAsset ||
          (manifest != null &&
              name ==
                  AssetNaming.originalDocument(
                    '.${manifest.sourceFormat.wireValue}',
                  ));

      final path = isRoot ? name : file.name;
      assets.add(_AssetFile(path, file.content));
    }

    return _FileReassembleResult(manifest, pages, assets);
  }

  static _DirectoryReassembleResult _reassembleToDirectoryIsolate(
    Map<String, dynamic> args,
  ) {
    final zip = args['zip'] as Uint8List;
    final outputDirectory = args['outputDirectory'] as String;
    final alreadyWrittenAssets = args['writtenAssets'] as Set<String>;
    final hasCoverBytes = args['hasCoverBytes'] as bool;
    final hasSourceBytes = args['hasSourceBytes'] as bool;

    final archive = ZipDecoder().decodeBytes(zip);
    BookManifest? manifest;
    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile != null) {
      manifest = BookManifest.fromJson(
        _jsonUtf8.convert(manifestFile.content as List<int>)
            as Map<String, Object?>,
      );
    }

    final pages = <_PageRow>[];
    final pagesFile = archive.findFile('pages.json');
    if (pagesFile != null) {
      final decoded = _jsonUtf8.convert(pagesFile.content as List<int>) as List;
      for (final p in decoded) {
        final map = p as Map<String, Object?>;
        final pageNumber = map['pageNumber'] as int;
        final chapterIndex = map['chapterIndex'] as int;
        pages.add(_PageRow(pageNumber - 1, chapterIndex, jsonEncode(map)));
      }
    }

    final newlyWrittenAssets = <String>{};
    for (final file in archive.files) {
      if (!file.name.startsWith('assets/')) continue;
      final name = file.name.substring('assets/'.length);
      if (!_isSafeAssetName(name)) continue;
      if (file.size > _maxAssetBytes) {
        throw StateError('Segment asset ${file.name} exceeds size limit');
      }
      if (alreadyWrittenAssets.contains(name) ||
          newlyWrittenAssets.contains(name)) {
        continue;
      }

      if (hasCoverBytes && name == manifest?.coverAsset) continue;
      if (hasSourceBytes &&
          manifest != null &&
          name ==
              AssetNaming.originalDocument(
                '.${manifest.sourceFormat.wireValue}',
              )) {
        continue;
      }

      final isRoot =
          name == manifest?.coverAsset ||
          (manifest != null &&
              name ==
                  AssetNaming.originalDocument(
                    '.${manifest.sourceFormat.wireValue}',
                  ));

      final destFile = isRoot
          ? File('$outputDirectory/$name')
          : File('$outputDirectory/assets/$name');

      if (!destFile.parent.existsSync()) {
        destFile.parent.createSync(recursive: true);
      }
      destFile.writeAsBytesSync(file.content as List<int>);
      newlyWrittenAssets.add(name);
    }

    return _DirectoryReassembleResult(manifest, pages, newlyWrittenAssets);
  }

  Future<void> reassembleToDirectory(
    Stream<Uint8List> segmentZips,
    String outputDirectory, {
    Uint8List? coverBytes,
    Uint8List? sourceBytes,
  }) async {
    final dir = Directory(outputDirectory);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final dbPath = '$outputDirectory/pages.db';
    final db = sqlite3.open(dbPath);
    db.execute('PRAGMA journal_mode=WAL;');
    db.execute(
      'CREATE TABLE IF NOT EXISTS pages (page_index INTEGER PRIMARY KEY, chapter_index INTEGER, json TEXT)',
    );

    try {
      final stmt = db.prepare(
        'INSERT OR REPLACE INTO pages (page_index, chapter_index, json) VALUES (?, ?, ?)',
      );

      BookManifest? manifest;
      final writtenAssets = <String>{};

      await for (final zip in segmentZips) {
        final result = await Isolate.run(
          () => _reassembleToDirectoryIsolate({
            'zip': zip,
            'outputDirectory': outputDirectory,
            'writtenAssets': writtenAssets,
            'hasCoverBytes': coverBytes != null,
            'hasSourceBytes': sourceBytes != null,
          }),
        );

        manifest ??= result.manifest;
        writtenAssets.addAll(result.writtenAssets);

        for (final page in result.pages) {
          stmt.execute([page.pageIndex, page.chapterIndex, page.json]);
        }
      }

      if (manifest == null) {
        throw StateError('No manifest found in segments');
      }

      final manifestBytes = _json(manifest.toJson());
      File('$outputDirectory/manifest.json').writeAsBytesSync(manifestBytes);

      if (coverBytes != null) {
        File(
          '$outputDirectory/${manifest.coverAsset}',
        ).writeAsBytesSync(coverBytes);
      }
      if (sourceBytes != null) {
        final ext = manifest.sourceFormat.wireValue;
        final name = AssetNaming.originalDocument('.$ext');
        File('$outputDirectory/$name').writeAsBytesSync(sourceBytes);
      }
    } finally {
      db.close();
    }
  }

  List<BookPage> _pagesFrom(Archive archive) {
    final file = archive.findFile('pages.json');
    if (file == null) return const [];
    final decoded = _jsonUtf8.convert(file.content) as List;
    return [
      for (final page in decoded)
        BookPage.fromJson(page as Map<String, Object?>),
    ];
  }

  List<BookChapter> _chaptersFrom(List<BookPage> pages) {
    final byChapter = <int, List<BookPage>>{};
    for (final page in pages) {
      (byChapter[page.chapterIndex] ??= []).add(page);
    }
    return byChapter.entries
        .map(
          (entry) => BookChapter(
            index: entry.key,
            title: entry.value.isEmpty ? '' : entry.value.first.chapterTitle,
            pages: entry.value,
          ),
        )
        .toList()
      ..sort((a, b) => a.index.compareTo(b.index));
  }

  Uint8List _json(Object? value) =>
      Uint8List.fromList(JsonUtf8Encoder().convert(value));
}

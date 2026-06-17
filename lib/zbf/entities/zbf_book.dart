import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'package:zapbook/zbf/entities/book_chapter.dart';
import 'package:zapbook/zbf/entities/book_manifest.dart';

final class ZbfBook extends Equatable {
  const ZbfBook({
    required this.manifest,
    required this.chapters,
    required this.assets,
    this.fileAssets = const {},
  });

  final BookManifest manifest;
  final List<BookChapter> chapters;
  final Map<String, Uint8List> assets;
  final Map<String, String> fileAssets;

  ZbfBook copyWith({
    BookManifest? manifest,
    List<BookChapter>? chapters,
    Map<String, Uint8List>? assets,
    Map<String, String>? fileAssets,
  }) {
    return ZbfBook(
      manifest: manifest ?? this.manifest,
      chapters: chapters ?? this.chapters,
      assets: assets ?? this.assets,
      fileAssets: fileAssets ?? this.fileAssets,
    );
  }

  @override
  List<Object?> get props => [
    manifest,
    chapters,
    assets.keys.toList(),
    fileAssets,
  ];

  @override
  String toString() {
    return 'ZbfBook(manifest: $manifest, chapters: $chapters, assets: ${assets.keys.toList()}, fileAssets: $fileAssets)';
  }
}

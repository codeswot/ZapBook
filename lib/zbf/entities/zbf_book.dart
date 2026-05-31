import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'package:zapbook/zbf/entities/book_chapter.dart';
import 'package:zapbook/zbf/entities/book_manifest.dart';

final class ZbfBook extends Equatable {
  const ZbfBook({
    required this.manifest,
    required this.chapters,
    required this.assets,
  });

  final BookManifest manifest;
  final List<BookChapter> chapters;
  final Map<String, Uint8List> assets;

  ZbfBook copyWith({
    BookManifest? manifest,
    List<BookChapter>? chapters,
    Map<String, Uint8List>? assets,
  }) {
    return ZbfBook(
      manifest: manifest ?? this.manifest,
      chapters: chapters ?? this.chapters,
      assets: assets ?? this.assets,
    );
  }

  @override
  List<Object?> get props => [manifest, chapters, assets.keys.toList()];

  @override
  String toString() {
    return 'ZbfBook(manifest: $manifest, chapters: $chapters, assets: ${assets.keys.toList()})';
  }
}

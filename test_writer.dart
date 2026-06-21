import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:zapbook/zbf/entities/zbf_book.dart';
import 'package:zapbook/zbf/entities/book_manifest.dart';
import 'package:zapbook/zbf/enums/book_source_format.dart';
import 'package:zapbook/zbf/zbf_writer.dart';

void main() async {
  final manifest = BookManifest(
    id: 'test_book',
    title: 'Test',
    author: 'Author',
    sourceFormat: BookSourceFormat.epub,
    pageCount: 1,
    chapterCount: 1,
    coverAsset: 'cover.png',
    createdAt: DateTime.now(),
    needsAiProcessing: false,
    chapters: const [],
  );

  final book = ZbfBook(
    manifest: manifest,
    assets: {
      'cover.png': Uint8List.fromList([1, 2, 3]),
      'page_1.png': Uint8List.fromList([4, 5, 6]),
    },
  );

  final writer = ZbfWriter();
  final path = await writer.write(book, 'test_output');
  if (kDebugMode) {
    print('Written to $path');
  }

  final dir = Directory('test_output');
  for (final e in dir.listSync(recursive: true)) {
    if (kDebugMode) {
      print(e.path);
    }
  }
}

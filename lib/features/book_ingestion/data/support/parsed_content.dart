import 'dart:typed_data';

import 'package:zapbook/zbf/zbf.dart';

final class ParsedContent {
  const ParsedContent({
    required this.title,
    required this.author,
    required this.needsAiProcessing,
    required this.chapters,
    this.assets = const {},
    this.coverSource,
  });

  final String title;
  final String author;
  final bool needsAiProcessing;
  final List<BookChapter> chapters;
  final Map<String, Uint8List> assets;
  final Uint8List? coverSource;
}

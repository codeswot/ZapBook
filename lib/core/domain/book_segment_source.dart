import 'dart:typed_data';

import 'package:zapbook/zbf/entities/book_page.dart';

class SegmentData {
  const SegmentData({
    required this.pageStart,
    required this.pages,
    required this.assets,
  });

  final int pageStart;
  final List<BookPage> pages;
  final Map<String, Uint8List> assets;
}

typedef BookSegmentLoader = Future<SegmentData?> Function(int pageIndex);

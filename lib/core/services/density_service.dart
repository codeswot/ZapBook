import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reading_progress/reading_progress.dart';

import 'package:zapbook/features/book_reader/data/book_density_mapper.dart';
import 'package:zapbook/zbf/zbf.dart';

@lazySingleton
class DensityService {
  String? _dirPath;

  Future<String> _dir() async {
    if (_dirPath != null) return _dirPath!;
    final appDir = await getApplicationSupportDirectory();
    final dir = Directory('${appDir.path}/densities');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _dirPath = dir.path;
    return dir.path;
  }

  Future<void> precalc(String bookId, ZbfBook book) async {
    final pages = <BookPage>[];
    for (final chapter in book.chapters) {
      pages.addAll(chapter.pages);
    }
    final density = bookDensityFromPages(pages, genre: book.manifest.genre);
    final json = _toJson(density);
    final dir = await _dir();
    await File('$dir/$bookId.json').writeAsString(jsonEncode(json));
  }

  BookDensity? load(String bookId) {
    final dir = _dirPath;
    if (dir == null) return null;
    final file = File('$dir/$bookId.json');
    if (!file.existsSync()) return null;
    try {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      return _fromJson(json);
    } on Object {
      return null;
    }
  }

  Map<String, dynamic> _toJson(BookDensity d) => {
        'page_words': d.pageWords,
        'skippable_pages': d.skippablePages.toList(),
        'genre': d.genre.index,
      };

  BookDensity _fromJson(Map<String, dynamic> json) => BookDensity(
        pageWords: (json['page_words'] as List).cast<int>(),
        skippablePages:
            (json['skippable_pages'] as List).map((e) => e as int).toSet(),
        genre: Genre.values[json['genre'] as int],
      );
}

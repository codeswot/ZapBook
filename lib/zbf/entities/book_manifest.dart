import 'package:equatable/equatable.dart';

import 'package:zapbook/zbf/enums/book_source_format.dart';
import 'package:zapbook/zbf/entities/chapter_summary.dart';

final class BookManifest extends Equatable {
  const BookManifest({
    required this.id,
    required this.title,
    required this.author,
    this.genres = const [],
    required this.sourceFormat,
    required this.pageCount,
    required this.chapterCount,
    required this.coverAsset,
    required this.createdAt,
    required this.needsAiProcessing,
    this.chapters = const [],
    this.zbfVersion = currentZbfVersion,
    this.pageWords,
    this.skippablePages,
  });

  static const String currentZbfVersion = '1.0.0';

  final String zbfVersion;
  final String id;
  final String title;
  final String author;
  final List<String> genres;
  final BookSourceFormat sourceFormat;
  final int pageCount;
  final int chapterCount;
  final String coverAsset;
  final DateTime createdAt;
  final bool needsAiProcessing;
  final List<ChapterSummary> chapters;
  final List<int>? pageWords;
  final List<int>? skippablePages;

  Map<String, Object?> toJson() => {
        'zbfVersion': zbfVersion,
        'id': id,
        'title': title,
        'author': author,
        'genres': genres,
        'sourceFormat': sourceFormat.wireValue,
        'pageCount': pageCount,
        'chapterCount': chapterCount,
        'coverAsset': coverAsset,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'needsAiProcessing': needsAiProcessing,
        'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
        if (pageWords != null) 'pageWords': pageWords,
        if (skippablePages != null)
          'skippablePages': skippablePages!.toList(),
      };

  factory BookManifest.fromJson(Map<String, Object?> json) {
    final rawChapters = json['chapters'] as List<Object?>?;

    List<String> parsedGenres = [];

    if (json['genres'] is List) {
      parsedGenres = (json['genres'] as List)
          .map((e) => e.toString())
          .toList();
    } else if (json['genre'] is String) {
      parsedGenres = (json['genre'] as String)
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return BookManifest(
      zbfVersion: (json['zbfVersion'] as String?) ?? currentZbfVersion,
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      genres: parsedGenres,
      sourceFormat: BookSourceFormat.fromWire(json['sourceFormat'] as String),
      pageCount: (json['pageCount'] as num).toInt(),
      chapterCount: (json['chapterCount'] as num).toInt(),
      coverAsset: json['coverAsset'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      needsAiProcessing: json['needsAiProcessing'] as bool,
      chapters: rawChapters
              ?.map(
                (chapter) => ChapterSummary.fromJson(
                  chapter as Map<String, Object?>,
                ),
              )
              .toList() ??
          const [],
      pageWords: (json['pageWords'] as List?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      skippablePages: (json['skippablePages'] as List?)
          ?.map((e) => (e as num).toInt())
          .toSet()
          .toList(),
    );
  }

  BookManifest copyWith({
    String? zbfVersion,
    String? id,
    String? title,
    String? author,
    List<String>? genres,
    BookSourceFormat? sourceFormat,
    int? pageCount,
    int? chapterCount,
    String? coverAsset,
    DateTime? createdAt,
    bool? needsAiProcessing,
    List<ChapterSummary>? chapters,
    List<int>? pageWords,
    List<int>? skippablePages,
  }) {
    return BookManifest(
      zbfVersion: zbfVersion ?? this.zbfVersion,
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      genres: genres ?? this.genres,
      sourceFormat: sourceFormat ?? this.sourceFormat,
      pageCount: pageCount ?? this.pageCount,
      chapterCount: chapterCount ?? this.chapterCount,
      coverAsset: coverAsset ?? this.coverAsset,
      createdAt: createdAt ?? this.createdAt,
      needsAiProcessing: needsAiProcessing ?? this.needsAiProcessing,
      chapters: chapters ?? this.chapters,
      pageWords: pageWords ?? this.pageWords,
      skippablePages: skippablePages ?? this.skippablePages,
    );
  }

  @override
  List<Object?> get props => [
        zbfVersion,
        id,
        title,
        author,
        genres,
        sourceFormat,
        pageCount,
        chapterCount,
        coverAsset,
        createdAt,
        needsAiProcessing,
        chapters,
        pageWords,
        skippablePages,
      ];
}
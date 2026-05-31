import 'package:equatable/equatable.dart';

import 'package:zapbook/zbf/enums/book_source_format.dart';
import 'package:zapbook/zbf/entities/chapter_summary.dart';

final class BookManifest extends Equatable {
  const BookManifest({
    required this.id,
    required this.title,
    required this.author,
    this.genre,
    required this.sourceFormat,
    required this.pageCount,
    required this.chapterCount,
    required this.coverAsset,
    required this.createdAt,
    required this.needsAiProcessing,
    this.chapters = const [],
    this.zbfVersion = currentZbfVersion,
  });

  static const String currentZbfVersion = '1.0.0';

  final String zbfVersion;
  final String id;
  final String title;
  final String author;
  final String? genre;
  final BookSourceFormat sourceFormat;
  final int pageCount;
  final int chapterCount;
  final String coverAsset;
  final DateTime createdAt;
  final bool needsAiProcessing;
  final List<ChapterSummary> chapters;

  Map<String, Object?> toJson() => {
    'zbfVersion': zbfVersion,
    'id': id,
    'title': title,
    'author': author,
    if (genre != null) 'genre': genre,
    'sourceFormat': sourceFormat.wireValue,
    'pageCount': pageCount,
    'chapterCount': chapterCount,
    'coverAsset': coverAsset,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'needsAiProcessing': needsAiProcessing,
    'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
  };

  factory BookManifest.fromJson(Map<String, Object?> json) {
    final rawChapters = json['chapters'] as List<Object?>?;
    return BookManifest(
      zbfVersion: (json['zbfVersion'] as String?) ?? currentZbfVersion,
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      genre: json['genre'] as String?,
      sourceFormat: BookSourceFormat.fromWire(json['sourceFormat'] as String),
      pageCount: (json['pageCount'] as num).toInt(),
      chapterCount: (json['chapterCount'] as num).toInt(),
      coverAsset: json['coverAsset'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      needsAiProcessing: json['needsAiProcessing'] as bool,
      chapters:
          rawChapters
              ?.map(
                (chapter) =>
                    ChapterSummary.fromJson(chapter as Map<String, Object?>),
              )
              .toList() ??
          const [],
    );
  }

  BookManifest copyWith({
    String? zbfVersion,
    String? id,
    String? title,
    String? author,
    String? genre,
    BookSourceFormat? sourceFormat,
    int? pageCount,
    int? chapterCount,
    String? coverAsset,
    DateTime? createdAt,
    bool? needsAiProcessing,
    List<ChapterSummary>? chapters,
  }) {
    return BookManifest(
      zbfVersion: zbfVersion ?? this.zbfVersion,
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      genre: genre ?? this.genre,
      sourceFormat: sourceFormat ?? this.sourceFormat,
      pageCount: pageCount ?? this.pageCount,
      chapterCount: chapterCount ?? this.chapterCount,
      coverAsset: coverAsset ?? this.coverAsset,
      createdAt: createdAt ?? this.createdAt,
      needsAiProcessing: needsAiProcessing ?? this.needsAiProcessing,
      chapters: chapters ?? this.chapters,
    );
  }

  @override
  List<Object?> get props => [
    zbfVersion,
    id,
    title,
    author,
    genre,
    sourceFormat,
    pageCount,
    chapterCount,
    coverAsset,
    createdAt,
    needsAiProcessing,
    chapters,
  ];
}

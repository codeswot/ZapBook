import 'package:equatable/equatable.dart';

import 'package:zapbook/zbf/enums/book_source_format.dart';

final class LibraryBook extends Equatable {
  const LibraryBook({
    required this.id,
    required this.title,
    required this.author,
    this.genre,
    required this.sourceFormat,
    required this.pageCount,
    required this.chapterCount,
    required this.zbfPath,
    this.coverPath,
    required this.needsAiProcessing,
    required this.zbfVersion,
    required this.createdAt,
    required this.addedAt,
    this.lastOpenedAt,
    this.contentHash,
  });

  final String id;
  final String title;
  final String author;
  final String? genre;
  final BookSourceFormat sourceFormat;
  final int pageCount;
  final int chapterCount;
  final String zbfPath;
  final String? coverPath;
  final bool needsAiProcessing;
  final String zbfVersion;
  final DateTime createdAt;
  final DateTime addedAt;
  final DateTime? lastOpenedAt;
  final String? contentHash;

  @override
  List<Object?> get props => [
    id,
    title,
    author,
    genre,
    sourceFormat,
    pageCount,
    chapterCount,
    zbfPath,
    coverPath,
    needsAiProcessing,
    zbfVersion,
    createdAt,
    addedAt,
    lastOpenedAt,
    contentHash,
  ];
}

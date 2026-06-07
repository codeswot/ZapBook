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
    this.memberCount = 1,
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
  final int memberCount;

  bool get isShared => memberCount > 1;

  LibraryBook copyWith({
    String? title,
    String? author,
    String? genre,
    String? coverPath,
    DateTime? lastOpenedAt,
    int? memberCount,
  }) {
    return LibraryBook(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      genre: genre ?? this.genre,
      sourceFormat: sourceFormat,
      pageCount: pageCount,
      chapterCount: chapterCount,
      zbfPath: zbfPath,
      coverPath: coverPath ?? this.coverPath,
      needsAiProcessing: needsAiProcessing,
      zbfVersion: zbfVersion,
      createdAt: createdAt,
      addedAt: addedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      contentHash: contentHash,
      memberCount: memberCount ?? this.memberCount,
    );
  }

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
    memberCount,
  ];
}

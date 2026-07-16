import 'dart:io';
import 'package:equatable/equatable.dart';

import 'package:zapbook/zbf/enums/book_source_format.dart';

final class CircleBook extends Equatable {
  const CircleBook({
    required this.id,
    required this.nostrGroudId,
    required this.circleDirId,
    required this.title,
    required this.author,
    this.genres = const [],
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
    this.adminNpubs = const [],
    this.removedFromCircle = false,
  });

  final String id;
  final String nostrGroudId;
  final String circleDirId;
  final String title;
  final String author;
  final List<String> genres;
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
  final List<String> adminNpubs;
  final bool removedFromCircle;

  bool get isShared => memberCount > 1;
  bool get isDownloaded => File('$zbfPath/manifest.json').existsSync();

  CircleBook copyWith({
    String? title,
    String? author,
    List<String>? genres,
    String? coverPath,
    DateTime? lastOpenedAt,
    int? memberCount,
    List<String>? adminNpubs,
    bool? removedFromCircle,
  }) {
    return CircleBook(
      id: id,
      nostrGroudId: nostrGroudId,
      circleDirId: circleDirId,
      title: title ?? this.title,
      author: author ?? this.author,
      genres: genres ?? this.genres,
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
      adminNpubs: adminNpubs ?? this.adminNpubs,
      removedFromCircle: removedFromCircle ?? this.removedFromCircle,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    author,
    genres,
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
    adminNpubs,
    removedFromCircle,
  ];
}

abstract final class BookMessageType {
  static const meta = 'zapbook.book.meta';
  static const progress = 'zapbook.book.progress';
}

class BookMetaPayload {
  const BookMetaPayload({
    required this.bookId,
    required this.title,
    required this.author,
    this.genre,
    this.contentHash,
    required this.sourceFormat,
    required this.pageCount,
    required this.chapterCount,
    required this.zbfVersion,
    required this.needsAiProcessing,
    required this.createdAtMs,
    required this.addedAtMs,
    this.pageWords,
    this.skippablePages,
  });

  final String bookId;
  final String title;
  final String author;
  final String? genre;
  final String? contentHash;
  final String sourceFormat;
  final int pageCount;
  final int chapterCount;
  final String zbfVersion;
  final bool needsAiProcessing;
  final int createdAtMs;
  final int addedAtMs;
  final List<int>? pageWords;
  final List<int>? skippablePages;

  Map<String, dynamic> toJson() => {
    'type': BookMessageType.meta,
    'bookId': bookId,
    'title': title,
    'author': author,
    'genre': genre,
    'contentHash': contentHash,
    'sourceFormat': sourceFormat,
    'pageCount': pageCount,
    'chapterCount': chapterCount,
    'zbfVersion': zbfVersion,
    'needsAiProcessing': needsAiProcessing,
    'createdAtMs': createdAtMs,
    'addedAtMs': addedAtMs,
    if (pageWords != null) 'pageWords': pageWords,
    if (skippablePages != null) 'skippablePages': skippablePages,
  };

  BookMetaPayload copyWith({String? title, String? author, String? genre}) {
    return BookMetaPayload(
      bookId: bookId,
      title: title ?? this.title,
      author: author ?? this.author,
      genre: genre ?? this.genre,
      contentHash: contentHash,
      sourceFormat: sourceFormat,
      pageCount: pageCount,
      chapterCount: chapterCount,
      zbfVersion: zbfVersion,
      needsAiProcessing: needsAiProcessing,
      createdAtMs: createdAtMs,
      addedAtMs: addedAtMs,
      pageWords: pageWords,
      skippablePages: skippablePages,
    );
  }

  factory BookMetaPayload.fromJson(Map<String, dynamic> json) =>
      BookMetaPayload(
        bookId: json['bookId'] as String,
        title: json['title'] as String? ?? 'Untitled',
        author: json['author'] as String? ?? '',
        genre: json['genre'] as String?,
        contentHash: json['contentHash'] as String?,
        sourceFormat: json['sourceFormat'] as String? ?? 'unknown',
        pageCount: (json['pageCount'] as num?)?.toInt() ?? 0,
        chapterCount: (json['chapterCount'] as num?)?.toInt() ?? 0,
        zbfVersion: json['zbfVersion'] as String? ?? '',
        needsAiProcessing: json['needsAiProcessing'] as bool? ?? false,
        createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
        addedAtMs: (json['addedAtMs'] as num?)?.toInt() ?? 0,
        pageWords: (json['pageWords'] as List?)
            ?.map((e) => (e as num).toInt())
            .toList(),
        skippablePages: (json['skippablePages'] as List?)
            ?.map((e) => (e as num).toInt())
            .toList(),
      );
}

class BookProgressPayload {
  const BookProgressPayload({
    required this.bookId,
    required this.lastReadAtMs,
    this.currentPage,
    this.currentWordCount,
    this.totalWordCount,
  });

  final String bookId;
  final int lastReadAtMs;
  final int? currentPage;
  final int? currentWordCount;
  final int? totalWordCount;

  Map<String, dynamic> toJson() => {
    'type': BookMessageType.progress,
    'bookId': bookId,
    'lastReadAtMs': lastReadAtMs,
    if (currentPage != null) 'currentPage': currentPage,
    if (currentWordCount != null) 'currentWordCount': currentWordCount,
    if (totalWordCount != null) 'totalWordCount': totalWordCount,
  };

  factory BookProgressPayload.fromJson(Map<String, dynamic> json) =>
      BookProgressPayload(
        bookId: json['bookId'] as String,
        lastReadAtMs: (json['lastReadAtMs'] as num?)?.toInt() ?? 0,
        currentPage: (json['currentPage'] as num?)?.toInt(),
        currentWordCount: (json['currentWordCount'] as num?)?.toInt(),
        totalWordCount: (json['totalWordCount'] as num?)?.toInt(),
      );
}

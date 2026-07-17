class BookSearchHit {
  const BookSearchHit({
    required this.circleDirId,
    required this.pageNumber,
    required this.chapterTitle,
    required this.snippet,
  });

  static const highlightStart = '‹';
  static const highlightEnd = '›';

  final String circleDirId;
  final int pageNumber;
  final String chapterTitle;
  final String snippet;
}

class BlendedSearchResult {
  const BlendedSearchResult({
    required this.hits,
    required this.semanticAvailable,
  });

  final List<BookSearchHit> hits;
  final bool semanticAvailable;
}

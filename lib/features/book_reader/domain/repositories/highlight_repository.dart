import 'package:zapbook/features/book_reader/domain/entities/highlight.dart';

abstract class HighlightRepository {
  Future<Highlight?> saveHighlight({
    required String bookId,
    required int pageNumber,
    required List<HighlightSpan> spans,
    required String quoteSnapshot,
  });

  Future<void> addOrUpdateNote({
    required String highlightId,
    required String note,
  });

  Future<void> shareToCircle({
    required String highlightId,
    required String groupId,
  });

  Future<void> delete(String highlightId);

  Stream<List<Highlight>> watchPage({
    required String bookId,
    required int pageNumber,
  });

  Stream<List<Highlight>> watchBook(String bookId);
}

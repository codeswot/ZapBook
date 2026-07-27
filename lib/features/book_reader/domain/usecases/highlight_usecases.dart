import 'package:injectable/injectable.dart';
import 'package:zapbook/features/book_reader/domain/entities/highlight.dart';
import 'package:zapbook/features/book_reader/domain/repositories/highlight_repository.dart';

@injectable
class SaveHighlightUseCase {
  const SaveHighlightUseCase(this._repository);
  final HighlightRepository _repository;
  Future<Highlight?> call({
    required String bookId,
    required int pageNumber,
    required List<HighlightSpan> spans,
    required String quoteSnapshot,
  }) => _repository.saveHighlight(
    bookId: bookId,
    pageNumber: pageNumber,
    spans: spans,
    quoteSnapshot: quoteSnapshot,
  );
}

@injectable
class AddNoteUseCase {
  const AddNoteUseCase(this._repository);
  final HighlightRepository _repository;
  Future<void> call({required String highlightId, required String note}) =>
      _repository.addOrUpdateNote(highlightId: highlightId, note: note);
}

@injectable
class ShareHighlightToCircleUseCase {
  const ShareHighlightToCircleUseCase(this._repository);
  final HighlightRepository _repository;
  Future<void> call({required String highlightId, required String groupId}) =>
      _repository.shareToCircle(highlightId: highlightId, groupId: groupId);
}

@injectable
class DeleteHighlightUseCase {
  const DeleteHighlightUseCase(this._repository);
  final HighlightRepository _repository;
  Future<void> call(String highlightId) => _repository.delete(highlightId);
}

@injectable
class WatchHighlightsForPageUseCase {
  const WatchHighlightsForPageUseCase(this._repository);
  final HighlightRepository _repository;
  Stream<List<Highlight>> call({
    required String bookId,
    required int pageNumber,
  }) => _repository.watchPage(bookId: bookId, pageNumber: pageNumber);
}

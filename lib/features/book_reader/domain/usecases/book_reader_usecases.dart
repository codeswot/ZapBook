import 'package:injectable/injectable.dart';
import 'package:reading_progress/reading_progress.dart';
import 'package:zapbook/core/models/book_download_progress.dart';
import 'package:zapbook/features/book_reader/domain/repositories/book_reader_repository.dart';
import 'package:zapbook/zbf/zbf.dart';

@injectable
class SaveReadingSnapshotUseCase {
  const SaveReadingSnapshotUseCase(this._repository);

  final BookReaderRepository _repository;

  Future<void> call(String circleDirId, ReadingState state, {double? scrollOffset}) =>
      _repository.saveSnapshot(circleDirId, state, scrollOffset: scrollOffset);
}

@injectable
class LoadReadingSnapshotUseCase {
  const LoadReadingSnapshotUseCase(this._repository);

  final BookReaderRepository _repository;

  Future<({ReadingState state, double? scrollOffset})?> call(String circleDirId) =>
      _repository.loadSnapshot(circleDirId);
}

@injectable
class ReportReadingProgressUseCase {
  const ReportReadingProgressUseCase(this._repository);

  final BookReaderRepository _repository;

  void report({
    required String circleDirId,
    required String groupId,
    required int currentPage,
    required int currentWordCount,
    required int totalWords,
    required double fraction,
    int milestonesReached = 0,
    bool bookCompleted = false,
  }) {
    _repository.reportProgress(
      circleDirId: circleDirId,
      groupId: groupId,
      currentPage: currentPage,
      currentWordCount: currentWordCount,
      totalWords: totalWords,
      fraction: fraction,
      milestonesReached: milestonesReached,
      bookCompleted: bookCompleted,
    );
  }

  void flush(String circleDirId) => _repository.flushProgress(circleDirId);

  void close(String circleDirId) => _repository.closeBook(circleDirId);
}

@injectable
class GetBookContentUseCase {
  const GetBookContentUseCase(this._repository);

  final BookReaderRepository _repository;

  Future<Map<int, BookPage>> call(String bookId) =>
      _repository.loadBookContent(bookId);
}

@injectable
class SaveBookContentUseCase {
  const SaveBookContentUseCase(this._repository);

  final BookReaderRepository _repository;

  Future<void> call(String bookId, Map<int, BookPage> pages) =>
      _repository.savePages(bookId, pages);
}

@injectable
class WatchBookDownloadProgressUseCase {
  const WatchBookDownloadProgressUseCase(this._repository);

  final BookReaderRepository _repository;

  Stream<BookDownloadProgress> call() =>
      _repository.watchBookDownloadProgress();
}

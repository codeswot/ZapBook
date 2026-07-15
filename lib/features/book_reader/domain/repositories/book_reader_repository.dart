import 'package:reading_progress/reading_progress.dart';
import 'package:zapbook/core/models/book_download_progress.dart';
import 'package:zapbook/zbf/zbf.dart';

abstract class BookReaderRepository {
  Future<void> saveSnapshot(
    String circleDirId,
    ReadingState state, {
    double? scrollOffset,
  });

  Future<({ReadingState state, double? scrollOffset})?> loadSnapshot(
    String circleDirId,
  );

  void reportProgress({
    required String circleDirId,
    required String groupId,
    required int currentPage,
    required int currentWordCount,
    required int totalWords,
    required double fraction,
    int milestonesReached = 0,
    bool bookCompleted = false,
  });

  void flushProgress(String circleDirId);

  void closeBook(String circleDirId);

  Future<void> savePages(String bookId, Map<int, BookPage> pages);
  Future<Map<int, BookPage>> loadBookContent(String bookId);
  Stream<BookDownloadProgress> watchBookDownloadProgress();
}

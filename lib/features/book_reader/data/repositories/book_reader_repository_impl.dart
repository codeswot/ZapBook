import 'package:injectable/injectable.dart';
import 'package:reading_progress/reading_progress.dart';
import 'package:zapbook/core/data/database/dao/page_dao.dart';
import 'package:zapbook/core/models/book_download_progress.dart';
import 'package:zapbook/core/services/circle_share_service.dart';
import 'package:zapbook/core/services/milestone_service.dart';
import 'package:zapbook/features/book_reader/data/reading_progress_local_store.dart';
import 'package:zapbook/features/book_reader/domain/repositories/book_reader_repository.dart';
import 'package:zapbook/zbf/zbf.dart';

@Injectable(as: BookReaderRepository)
class BookReaderRepositoryImpl implements BookReaderRepository {
  const BookReaderRepositoryImpl(
    this._localStore,
    this._milestoneService,
    this._pageDao,
    this._circleShareService,
  );

  final ReadingProgressLocalStore _localStore;
  final MilestoneService _milestoneService;
  final PageDao _pageDao;
  final CircleShareService _circleShareService;

  @override
  Future<void> saveSnapshot(String circleDirId, ReadingState state, {double? scrollOffset}) {
    return _localStore.saveSnapshot(circleDirId, state, scrollOffset: scrollOffset);
  }

  @override
  Future<({ReadingState state, double? scrollOffset})?> loadSnapshot(String circleDirId) {
    return _localStore.loadSnapshot(circleDirId);
  }

  @override
  void reportProgress({
    required String circleDirId,
    required String groupId,
    required int currentPage,
    required int currentWordCount,
    required int totalWords,
    required double fraction,
    int milestonesReached = 0,
    bool bookCompleted = false,
  }) {
    _milestoneService.reportProgress(
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

  @override
  void flushProgress(String circleDirId) {
    _milestoneService.flushProgress(circleDirId);
  }

  @override
  void closeBook(String circleDirId) {
    _milestoneService.closeBook(circleDirId);
  }

  @override
  Future<void> savePages(String bookId, Map<int, BookPage> pages) {
    return _pageDao.saveAll(bookId, pages);
  }

  @override
  Future<Map<int, BookPage>> loadBookContent(String bookId) {
    return _pageDao.load(bookId);
  }

  @override
  Stream<BookDownloadProgress> watchBookDownloadProgress() {
    return _circleShareService.onBookDownloadProgress;
  }
}

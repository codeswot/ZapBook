import 'package:zapbook/core/models/book_download_progress.dart';

abstract class BookDownloadRepository {
  Future<bool> fetchAndDownloadBook(String groupId, String circleDirId);
  Stream<BookDownloadProgress> watchBookDownloadProgress();
}

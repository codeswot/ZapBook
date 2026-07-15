import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/repositories/book_download_repository.dart';
import 'package:zapbook/core/models/book_download_progress.dart';

@injectable
class WatchGlobalBookDownloadProgress {
  const WatchGlobalBookDownloadProgress(this._repository);

  final BookDownloadRepository _repository;

  Stream<BookDownloadProgress> call() {
    return _repository.watchBookDownloadProgress();
  }
}

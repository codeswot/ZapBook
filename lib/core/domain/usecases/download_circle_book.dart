import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/repositories/book_download_repository.dart';

@injectable
class DownloadCircleBook {
  const DownloadCircleBook(this._repository);

  final BookDownloadRepository _repository;

  Future<bool> call(String groupId, String circleDirId) async {
    return _repository.fetchAndDownloadBook(groupId, circleDirId);
  }
}

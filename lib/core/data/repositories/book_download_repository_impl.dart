import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/repositories/book_download_repository.dart';
import 'package:zapbook/core/models/book_download_progress.dart';
import 'package:zapbook/core/services/circle_share_service.dart';

@Injectable(as: BookDownloadRepository)
class BookDownloadRepositoryImpl implements BookDownloadRepository {
  BookDownloadRepositoryImpl(this._circleShareService);

  final CircleShareService _circleShareService;

  @override
  Future<bool> fetchAndDownloadBook(String groupId, String circleDirId) {
    return _circleShareService.fetchAndDownloadBook(groupId, circleDirId);
  }

  @override
  Stream<BookDownloadProgress> watchBookDownloadProgress() {
    return _circleShareService.onBookDownloadProgress;
  }
}

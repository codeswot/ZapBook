import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:mime/mime.dart';
import 'package:zapbook/core/constants/app_constants.dart';
import 'package:zapbook/core/data/library_file_store.dart';
import 'package:zapbook/core/identity/active_account.dart';
import 'package:zapbook/core/services/circle_share_service.dart';
import 'package:zapbook/core/services/circle_store_service.dart';
import 'package:zapbook/features/book_ingestion/domain/repositories/ingestion_orchestrator_repository.dart';

@Injectable(as: IngestionOrchestratorRepository)
class IngestionOrchestratorRepositoryImpl implements IngestionOrchestratorRepository {
  IngestionOrchestratorRepositoryImpl(
    this._circleStore,
    this._circleShareService,
    this._fileStore,
  );

  final CircleStoreService _circleStore;
  final CircleShareService _circleShareService;
  final LibraryFileStore _fileStore;
  final _log = logging.Logger('IngestionOrchestratorRepositoryImpl');

  @override
  Future<String> createCircleBook({
    required String circleDirId,
    required String humanTitle,
    required Map<String, dynamic> metadata,
  }) async {
    return _circleStore.createCircleBook(
      circleDirId: circleDirId,
      humanTitle: humanTitle,
      metadata: metadata,
    );
  }

  @override
  Future<void> deleteBookFiles(String circleDirId) async {
    try {
      await _fileStore.deleteBook(circleDirId);
    } catch (e, stackTrace) {
      _log.warning(
        'Failed to delete book files for $circleDirId ',
        e,
        stackTrace,
      );
    }
  }

  @override
  Future<void> finalizeAndUploadBook({
    required String circleDirId,
    required String marmotGroupId,
  }) async {
    _circleStore.refreshBookCover(circleDirId);

    final npub = ActiveAccount.currentNpub;
    if (npub != null) {
      _circleShareService.uploadBookContent(npub, marmotGroupId, circleDirId);

      final coverPath = await _fileStore.coverPathIfExists(circleDirId);
      if (coverPath != null) {
        try {
          final coverBytes = await File(coverPath).readAsBytes();
          final preparedImage = await _circleStore.prepareCover(
            coverBytes: coverBytes,
          );
          final mimeType =
              lookupMimeType(coverPath) ?? AppConstants.defaultImageMimeType;

          _circleStore.updateCircleBookCoverOptimistic(
            marmotGroupId: marmotGroupId,
            circleDirId: circleDirId,
            coverBytes: coverBytes,
            preparedImage: preparedImage,
            mimeType: mimeType,
          );
        } catch (e, stackTrace) {
          _log.warning(
            'Failed to update book cover for $circleDirId ',
            e,
            stackTrace,
          );
        }
      }
    }
  }
}

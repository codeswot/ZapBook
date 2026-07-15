import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;

import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/presentation/bloc/circle_operations/circle_operations_state.dart';

import 'package:marmot_dart/marmot_dart.dart';
import 'package:mime/mime.dart';
import 'package:zapbook/core/constants/app_constants.dart';
import 'package:zapbook/features/circles/domain/usecases/circles_usecases.dart';

@injectable
class CircleOperationsCubit extends Cubit<CircleOperationsState> {
  CircleOperationsCubit(
    this._getMyNpubUseCase,
    this._deleteCircleBookUseCase,
    this._leaveCircleBookUseCase,
    this._prepareCircleCoverUseCase,
    this._updateCircleBookMetadataUseCase,
    this._setUploadingCoverUseCase,
    this._clearUploadingCoverUseCase,
    this._updateCircleBookCoverOptimisticUseCase,
  ) : super(const CircleOperationsInitial());

  final GetMyNpubUseCase _getMyNpubUseCase;
  final DeleteCircleBookUseCase _deleteCircleBookUseCase;
  final LeaveCircleBookUseCase _leaveCircleBookUseCase;
  final PrepareCircleCoverUseCase _prepareCircleCoverUseCase;
  final UpdateCircleBookMetadataUseCase _updateCircleBookMetadataUseCase;
  final SetUploadingCoverUseCase _setUploadingCoverUseCase;
  final ClearUploadingCoverUseCase _clearUploadingCoverUseCase;
  final UpdateCircleBookCoverOptimisticUseCase
  _updateCircleBookCoverOptimisticUseCase;

  final _log = logging.Logger('CircleOperationsCubit');

  Future<GroupImagePrepared> prepareCover(Uint8List coverBytes) async {
    return _prepareCircleCoverUseCase(coverBytes) as Future<GroupImagePrepared>;
  }

  Future<void> deleteBook(CircleBook book) async {
    try {
      emit(const CircleOperationsLoading());
      final isAdmin = await isAdminOf(book);
      if (!isAdmin) {
        await _leaveCircleBookUseCase(book);
      }
      await _deleteCircleBookUseCase(book);
      if (isClosed) return;
      emit(const CircleOperationsSuccess());
    } catch (e) {
      if (isClosed) return;
      emit(CircleOperationsFailure(e.toString()));
    }
  }

  Future<CircleBook?> updateBookMetadata({
    required CircleBook book,
    required String title,
    required String author,
    String? genre,
  }) async {
    try {
      emit(const CircleOperationsLoading());
      await _updateCircleBookMetadataUseCase(
        marmotGroupId: book.id,
        title: title,
        author: author,
        genre: genre,
      );

      if (isClosed) return null;
      emit(const CircleOperationsSuccess());
      return book.copyWith(title: title, author: author, genre: genre);
    } catch (e, st) {
      _log.warning('Failed to update book metadata', e, st);
      if (isClosed) return null;
      emit(CircleOperationsFailure(e.toString()));
      return null;
    }
  }

  void saveBookEditsInBackground({
    required CircleBook book,
    required String title,
    required String author,
    String? genre,
    Uint8List? coverBytes,
    Future<GroupImagePrepared>? pendingCoverUpload,
  }) {
    unawaited(() async {
      try {
        await _updateCircleBookMetadataUseCase(
          marmotGroupId: book.id,
          title: title,
          author: author,
          genre: genre,
        );

        if (coverBytes != null && pendingCoverUpload != null) {
          _setUploadingCoverUseCase(book.id, AppConstants.placeholderBlurHash);

          GroupImagePrepared preparedImage;
          try {
            preparedImage = await pendingCoverUpload;
          } catch (e) {
            _clearUploadingCoverUseCase(book.id);
            rethrow;
          }

          if (preparedImage.blurhash != null) {
            _setUploadingCoverUseCase(book.id, preparedImage.blurhash!);
          }

          final mimeType =
              lookupMimeType('', headerBytes: coverBytes) ??
              AppConstants.defaultImageMimeType;

          _updateCircleBookCoverOptimisticUseCase(
            marmotGroupId: book.id,
            circleDirId: book.circleDirId,
            coverBytes: coverBytes,
            preparedImage: preparedImage,
            mimeType: mimeType,
          );
        }
      } catch (e, st) {
        _log.warning('Failed background book save', e, st);
      }
    }());
  }

  Future<void> leaveCircle(CircleBook book) async {
    try {
      emit(const CircleOperationsLoading());
      await _leaveCircleBookUseCase(book);
      if (isClosed) return;
      emit(const CircleOperationsSuccess());
    } catch (e) {
      if (isClosed) return;
      emit(CircleOperationsFailure(e.toString()));
    }
  }

  Future<bool> isAdminOf(CircleBook book) async {
    final myNpub = await _getMyNpubUseCase();
    if (myNpub == null) return false;
    return book.adminNpubs.contains(myNpub);
  }

  Future<String> ownerLabelFor(CircleBook book) async => '';
}

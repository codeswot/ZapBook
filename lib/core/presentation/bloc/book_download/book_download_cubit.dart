import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/domain/usecases/download_circle_book.dart';
import 'package:zapbook/core/models/book_download_progress.dart';
import 'package:zapbook/core/presentation/bloc/book_download/book_download_state.dart';
import 'package:zapbook/core/domain/usecases/watch_global_book_download_progress.dart';

@injectable
class BookDownloadCubit extends Cubit<BookDownloadState> {
  BookDownloadCubit(this._downloadCircleBook, this._watchProgress)
    : super(const BookDownloadState()) {
    _progressSub = _watchProgress().listen((event) {
      if (isClosed) return;
      final newProgress = Map<String, int>.from(state.downloadProgress);
      newProgress[event.circleDirId] =
          (newProgress[event.circleDirId] ?? 0) + 1;
      emit(state.copyWith(downloadProgress: newProgress));
    });
  }

  final DownloadCircleBook _downloadCircleBook;
  final WatchGlobalBookDownloadProgress _watchProgress;
  late final StreamSubscription<BookDownloadProgress> _progressSub;

  @override
  Future<void> close() {
    _progressSub.cancel();
    return super.close();
  }

  Future<void> downloadBook(CircleBook book) async {
    return downloadBookByIds(book.id, book.circleDirId);
  }

  Future<void> downloadBookByIds(String groupId, String circleDirId) async {
    if (state.downloadingBookIds.contains(circleDirId)) return;

    final newDownloading = Set<String>.from(state.downloadingBookIds)
      ..add(circleDirId);
    emit(state.copyWith(downloadingBookIds: newDownloading, clearError: true));

    try {
      final success = await _downloadCircleBook(groupId, circleDirId);
      if (!success) {
        emit(state.copyWith(errorMessage: 'Failed to download book'));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to download book'));
    } finally {
      if (!isClosed) {
        final updatedDownloading = Set<String>.from(state.downloadingBookIds)
          ..remove(circleDirId);
        emit(state.copyWith(downloadingBookIds: updatedDownloading));
      }
    }
  }
}

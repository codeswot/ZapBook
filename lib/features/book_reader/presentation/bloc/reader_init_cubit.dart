import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:zapbook/core/presentation/bloc/book_download/book_download_cubit.dart';
import 'package:zapbook/zbf/zbf_reader.dart';

part 'reader_init_state.dart';

@injectable
class ReaderInitCubit extends Cubit<ReaderInitState> {
  ReaderInitCubit(this._reader) : super(const ReaderInitInitial());

  final ZbfReader _reader;
  StreamSubscription? _downloadSub;
  String? _zbfPath;

  void open(
    String zbfPath, {
    String? circleDirId,
    String? groupId,
    BookDownloadCubit? downloadCubit,
  }) {
    _zbfPath = zbfPath;

    emit(const ReaderInitLoading());

    if (downloadCubit != null && circleDirId != null && groupId != null) {
      _downloadSub?.cancel();
      _downloadSub = downloadCubit.stream.listen((dlState) {
        final isDownloading = dlState.downloadingBookIds.contains(circleDirId);
        final hasError = dlState.errorMessage != null;
        if (!isDownloading && !hasError && state is ReaderInitError) {
          _tryOpen();
        }
      });
    }

    _tryOpen();
  }

  Future<void> _tryOpen() async {
    if (_zbfPath == null) return;
    emit(const ReaderInitLoading());
    try {
      final handle = await _reader.open(_zbfPath!);
      if (!isClosed) {
        emit(ReaderInitLoaded(handle));
      } else {
        handle.close();
      }
    } catch (e) {
      if (!isClosed) {
        emit(ReaderInitError(e.toString()));
      }
    }
  }

  void retry() {
    _tryOpen();
  }

  @override
  Future<void> close() {
    _downloadSub?.cancel();
    final currentState = state;
    if (currentState is ReaderInitLoaded) {
      currentState.handle.close();
    }
    return super.close();
  }
}

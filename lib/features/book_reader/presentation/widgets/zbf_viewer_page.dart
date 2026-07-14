import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zapbook/core/presentation/widgets/app_button.dart';
import 'package:zapbook/core/presentation/bloc/book_download/book_download_cubit.dart';
import 'package:zapbook/core/presentation/bloc/book_download/book_download_state.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_loading.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';

import 'package:zapbook/features/book_reader/presentation/pages/reader_screen.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/reader_init_cubit.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/reading_progress_cubit.dart';
import 'package:zapbook/core/di/injection.dart';

part 'zbf_viewer_page_error.dart';
part 'zbf_viewer_page_loading.dart';

class ZbfViewerPage extends StatelessWidget {
  const ZbfViewerPage({
    required this.zbfPath,
    super.key,
    this.initialPage,
    this.highlightQuery,
    this.bookTitle,
    this.coverPath,
    this.circleDirId,
    this.groupId,
  });

  final String zbfPath;
  final int? initialPage;
  final String? highlightQuery;
  final String? bookTitle;
  final String? coverPath;
  final String? circleDirId;
  final String? groupId;

  @override
  Widget build(BuildContext context) {
    return _LocalReader(
      zbfPath: zbfPath,
      initialPage: initialPage,
      highlightQuery: highlightQuery,
      bookTitle: bookTitle,
      coverPath: coverPath,
      circleDirId: circleDirId,
      groupId: groupId,
    );
  }
}

class _LocalReader extends StatelessWidget {
  const _LocalReader({
    required this.zbfPath,
    this.initialPage,
    this.highlightQuery,
    this.bookTitle,
    this.coverPath,
    this.circleDirId,
    this.groupId,
  });

  final String zbfPath;
  final int? initialPage;
  final String? highlightQuery;
  final String? bookTitle;
  final String? coverPath;
  final String? circleDirId;
  final String? groupId;

  void _retryAndLoad(BuildContext context) {
    if (circleDirId != null && groupId != null) {
      context.read<BookDownloadCubit>().downloadBookByIds(
        groupId!,
        circleDirId!,
      );
    }
    context.read<ReaderInitCubit>().retry();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ReaderInitCubit>()
        ..open(
          zbfPath,
          circleDirId: circleDirId,
          groupId: groupId,
          downloadCubit: context.read<BookDownloadCubit>(),
        ),
      child: BlocBuilder<ReaderInitCubit, ReaderInitState>(
        builder: (context, state) {
          if (state is ReaderInitError) {
            return _ViewerError(
              message: state.message,
              onRetry: () => _retryAndLoad(context),
              bookTitle: bookTitle,
              coverPath: coverPath,
              circleDirId: circleDirId,
            );
          }
          if (state is ReaderInitLoaded) {
            return BlocProvider(
              create: (context) => getIt<ReadingProgressCubit>()
                ..open(
                  state.handle,
                  circleDirId: state.handle.manifest.id,
                  groupId: groupId ?? '',
                ),
              child: ReaderScreen(
                handle: state.handle,
                initialPage: initialPage,
                highlightQuery: highlightQuery,
                groupId: groupId ?? '',
              ),
            );
          }
          return const _ViewerLoading();
        },
      ),
    );
  }
}

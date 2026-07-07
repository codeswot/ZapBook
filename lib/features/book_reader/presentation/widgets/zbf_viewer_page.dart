import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zapbook/core/presentation/widgets/app_button.dart';
import 'package:zapbook/core/presentation/bloc/book_download/book_download_cubit.dart';
import 'package:zapbook/core/presentation/bloc/book_download/book_download_state.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_loading.dart';
import 'package:zapbook/theme/app_theme.dart';

import 'package:zapbook/features/book_reader/presentation/pages/reader_screen.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/reader_init_cubit.dart';
import 'package:zapbook/core/di/injection.dart';

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
      create: (context) => getIt<ReaderInitCubit>()..open(
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
            return ReaderScreen(
              handle: state.handle,
              initialPage: initialPage,
              highlightQuery: highlightQuery,
            );
          }
          return const _ViewerLoading();
        },
      ),
    );
  }
}

class _ViewerLoading extends StatelessWidget {
  const _ViewerLoading();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: const BackButton()),

    backgroundColor: context.colors.paper,
    body: const ReaderPageLoading(message: 'Opening…'),
  );
}

class _ViewerError extends StatelessWidget {
  const _ViewerError({
    required this.message,
    required this.onRetry,
    this.bookTitle,
    this.coverPath,
    this.circleDirId,
  });

  final String message;
  final VoidCallback onRetry;
  final String? bookTitle;
  final String? coverPath;
  final String? circleDirId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookDownloadCubit, BookDownloadState>(
      listenWhen: (previous, current) {
        if (circleDirId == null) return false;
        final wasDownloading = previous.downloadingBookIds.contains(
          circleDirId,
        );
        final isDownloading = current.downloadingBookIds.contains(circleDirId);

        final prevProgress = previous.downloadProgress[circleDirId] ?? 0;
        final currProgress = current.downloadProgress[circleDirId] ?? 0;

        return (wasDownloading && !isDownloading) ||
            (isDownloading && currProgress > prevProgress);
      },
      listener: (context, state) {
        if (state.errorMessage == null) {
          onRetry();
        }
      },
      builder: (context, state) {
        final isDownloading =
            circleDirId != null &&
            state.downloadingBookIds.contains(circleDirId);
        final downloadedSegments = state.downloadProgress[circleDirId] ?? 0;

        return Scaffold(
          appBar: AppBar(leading: const BackButton()),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (coverPath != null && File(coverPath!).existsSync())
                    Container(
                      width: double.infinity,
                      height: 320,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.colors.hairline2),
                        image: DecorationImage(
                          image: FileImage(File(coverPath!)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border(
                          top: BorderSide(color: context.colors.plum, width: 6),
                        ),
                        color: context.colors.mist,
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 56,
                        color: context.colors.plum,
                      ),
                    ),
                  const SizedBox(height: 64),
                  if (bookTitle != null)
                    Text(
                      bookTitle ?? 'Circle book not available',
                      style: context.typography.h3.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      'Circle book not available',
                      style: context.typography.h3.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    isDownloading
                        ? (downloadedSegments > 0
                              ? 'Downloading book... $downloadedSegments segments received. We are trying to open it as soon as possible.'
                              : 'Downloading book... Please wait.')
                        : (state.errorMessage ??
                              'We encountered an error while trying to initialize the reader. The book might be corrupted or still downloading.'),
                    style: context.typography.body.copyWith(
                      color: state.errorMessage != null
                          ? Colors.red
                          : context.colors.slate,
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: isDownloading
                        ? const CircularProgressIndicator()
                        : AppButton(
                            onTap: onRetry,
                            icon: Icons.refresh_rounded,
                            label: 'Retry initialization',
                          ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: AppButton(
                      onTap: () => context.pop(),
                      icon: Icons.arrow_back_rounded,
                      variant: AppButtonVariant.ghost,
                      label: 'Go back',
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

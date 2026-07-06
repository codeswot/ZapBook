import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zapbook/core/presentation/widgets/app_button.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_loading.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/zbf/zbf.dart';
import 'package:zapbook/features/book_reader/presentation/pages/reader_screen.dart';
import 'package:zapbook/core/di/injection.dart';

class ZbfViewerPage extends StatelessWidget {
  const ZbfViewerPage({
    required this.zbfPath,
    super.key,
    this.initialPage,
    this.highlightQuery,
    this.reader,
    this.bookTitle,
    this.coverPath,
  });

  final String zbfPath;
  final int? initialPage;
  final String? highlightQuery;
  final ZbfReader? reader;
  final String? bookTitle;
  final String? coverPath;

  @override
  Widget build(BuildContext context) {
    return _LocalReader(
      zbfPath: zbfPath,
      reader: reader ?? getIt<ZbfReader>(),
      initialPage: initialPage,
      highlightQuery: highlightQuery,
      bookTitle: bookTitle,
      coverPath: coverPath,
    );
  }
}

class _LocalReader extends StatefulWidget {
  const _LocalReader({
    required this.zbfPath,
    required this.reader,
    required this.initialPage,
    required this.highlightQuery,
    required this.bookTitle,
    required this.coverPath,
  });

  final String zbfPath;
  final ZbfReader reader;
  final int? initialPage;
  final String? highlightQuery;
  final String? bookTitle;
  final String? coverPath;

  @override
  State<_LocalReader> createState() => _LocalReaderState();
}

class _LocalReaderState extends State<_LocalReader> {
  Future<ZbfBookHandle>? _futureHandle;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _futureHandle = widget.reader.open(widget.zbfPath);
    });
  }

  @override
  void dispose() {
    _futureHandle?.then((handle) => handle.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ZbfBookHandle>(
      future: _futureHandle,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ViewerError(
            message: '${snapshot.error}',
            onRetry: _load,
            bookTitle: widget.bookTitle,
            coverPath: widget.coverPath,
          );
        }
        final handle = snapshot.data;
        if (handle == null) return const _ViewerLoading();
        return ReaderScreen(
          handle: handle,
          initialPage: widget.initialPage,
          highlightQuery: widget.highlightQuery,
        );
      },
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
  });

  final String message;
  final VoidCallback onRetry;
  final String? bookTitle;
  final String? coverPath;

  @override
  Widget build(BuildContext context) => Scaffold(
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
              'We encountered an error while trying to initialize the reader. The book might be corrupted or still downloading.',
              style: context.typography.body.copyWith(
                color: context.colors.slate,
              ),
            ),
            const Spacer(),
            Center(
              child: AppButton(
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
}

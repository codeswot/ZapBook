import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_loading.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/zbf/zbf.dart';
import 'package:zapbook/features/book_reader/presentation/pages/reader_screen.dart';
import 'package:zapbook/features/library/data/marmot/progressive_book_opener.dart';
import 'package:zapbook/core/di/injection.dart';

class ZbfViewerPage extends StatelessWidget {
  const ZbfViewerPage({
    required this.zbfPath,
    super.key,
    this.initialPage,
    this.highlightQuery,
    this.reader,
  });

  final String zbfPath;
  final int? initialPage;
  final String? highlightQuery;
  final ZbfReader? reader;

  String get _bookId {
    final type = FileSystemEntity.typeSync(zbfPath);
    if (type == FileSystemEntityType.directory) {
      return Uri.parse(zbfPath).pathSegments.where((s) => s.isNotEmpty).last;
    }
    return File(
      zbfPath,
    ).parent.uri.pathSegments.where((segment) => segment.isNotEmpty).last;
  }

  @override
  Widget build(BuildContext context) {
    if (File('$zbfPath/manifest.json').existsSync()) {
      return _LocalReader(
        zbfPath: zbfPath,
        reader: reader ?? getIt<ZbfReader>(),
        initialPage: initialPage,
        highlightQuery: highlightQuery,
      );
    }
    return _ProgressiveReader(
      bookId: _bookId,
      initialPage: initialPage,
      highlightQuery: highlightQuery,
    );
  }
}

class _LocalReader extends StatefulWidget {
  const _LocalReader({
    required this.zbfPath,
    required this.reader,
    required this.initialPage,
    required this.highlightQuery,
  });

  final String zbfPath;
  final ZbfReader reader;
  final int? initialPage;
  final String? highlightQuery;

  @override
  State<_LocalReader> createState() => _LocalReaderState();
}

class _LocalReaderState extends State<_LocalReader> {
  Future<ZbfBookHandle>? _openFuture;
  ZbfBookHandle? _handle;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _openFuture = widget.reader.open(widget.zbfPath).then((handle) {
      if (mounted) {
        _handle = handle;
      } else {
        handle.close();
      }
      return handle;
    });
  }

  @override
  void dispose() {
    _handle?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ZbfBookHandle>(
      future: _openFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ViewerError(message: '${snapshot.error}');
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

class _ProgressiveReader extends StatefulWidget {
  const _ProgressiveReader({
    required this.bookId,
    required this.initialPage,
    required this.highlightQuery,
  });

  final String bookId;
  final int? initialPage;
  final String? highlightQuery;

  @override
  State<_ProgressiveReader> createState() => _ProgressiveReaderState();
}

class _ProgressiveReaderState extends State<_ProgressiveReader> {
  ProgressiveBook? _book;
  String? _error;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _tryOpen();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _tryOpen() async {
    if (_disposed) return;
    try {
      final book = await getIt<ProgressiveBookOpener>().open(widget.bookId);
      if (_disposed) return;
      if (book != null) {
        setState(() => _book = book);
      } else {
        Future.delayed(const Duration(milliseconds: 1500), _tryOpen);
      }
    } catch (e) {
      if (_disposed) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ViewerError(message: _error!);
    }
    if (_book == null) {
      return const _ViewerLoading(message: 'Preparing book...');
    }
    return ReaderScreen(
      handle: _book!.handle,
      segmentLoader: _book!.loader,
      initialPage: widget.initialPage,
      highlightQuery: widget.highlightQuery,
    );
  }
}

class _ViewerLoading extends StatelessWidget {
  const _ViewerLoading({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.colors.paper,
    body: ReaderPageLoading(message: message ?? 'Opening…'),
  );
}

class _ViewerError extends StatelessWidget {
  const _ViewerError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Center(child: Text('Failed to open: $message')),
  );
}

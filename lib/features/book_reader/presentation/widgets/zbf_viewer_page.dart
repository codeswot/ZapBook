import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zapbook/zbf/zbf.dart';
import 'package:zapbook/features/book_reader/presentation/pages/reader_screen.dart';
import 'package:zapbook/features/library/data/marmot/progressive_book_opener.dart';
import 'package:zapbook/core/di/injection.dart';

class ZbfViewerPage extends StatelessWidget {
  const ZbfViewerPage({required this.zbfPath, super.key, this._reader});

  final String zbfPath;

  final ZbfReader? _reader;

  ZbfReader get _resolvedReader => _reader ?? getIt<ZbfReader>();

  bool get _hasLocalZbf => File(zbfPath).existsSync();

  String get _bookId => File(zbfPath)
      .parent
      .uri
      .pathSegments
      .where((segment) => segment.isNotEmpty)
      .last;

  @override
  Widget build(BuildContext context) {
    return _hasLocalZbf ? _buildLocal() : _buildProgressive();
  }

  Widget _buildLocal() {
    return FutureBuilder<ZbfBookHandle>(
      future: _resolvedReader.open(zbfPath),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _error('${snapshot.error}');
        final handle = snapshot.data;
        if (handle == null) return _loading();
        return ReaderScreen(handle: handle);
      },
    );
  }

  Widget _buildProgressive() {
    return FutureBuilder<ProgressiveBook?>(
      future: getIt<ProgressiveBookOpener>().open(_bookId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _error('${snapshot.error}');
        if (snapshot.connectionState != ConnectionState.done) return _loading();
        final book = snapshot.data;
        if (book == null) return _error('Book content not available yet');
        return ReaderScreen(handle: book.handle, segmentLoader: book.loader);
      },
    );
  }

  Widget _loading() =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));

  Widget _error(String message) => Scaffold(
    appBar: AppBar(),
    body: Center(child: Text('Failed to open: $message')),
  );
}

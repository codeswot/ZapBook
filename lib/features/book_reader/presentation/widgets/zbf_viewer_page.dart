import 'package:flutter/material.dart';
import 'package:zapbook/zbf/zbf.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_screen.dart';
import 'package:zapbook/core/di/injection.dart';

class ZbfViewerPage extends StatelessWidget {
  const ZbfViewerPage({required this.zbfPath, super.key, this._reader});

  final String zbfPath;

  final ZbfReader? _reader;

  ZbfReader get _resolvedReader => _reader ?? getIt<ZbfReader>();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ZbfBookHandle>(
      future: _resolvedReader.open(zbfPath),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Failed to open: ${snapshot.error}')),
          );
        }
        final handle = snapshot.data;
        if (handle == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return ReaderScreen(handle: handle);
      },
    );
  }
}

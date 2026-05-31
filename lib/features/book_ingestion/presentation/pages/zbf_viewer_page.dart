import 'package:flutter/material.dart';
import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/features/book_ingestion/presentation/widgets/zbf_book_view.dart';
import 'package:zapbook/core/di/injection.dart';

class ZbfViewerPage extends StatelessWidget {
  const ZbfViewerPage({required this.zbfPath, super.key, this._reader});

  final String zbfPath;
  final ZbfReader? _reader;

  ZbfReader get _resolvedReader => _reader ?? getIt<ZbfReader>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inspect ZBF')),
      body: FutureBuilder<ZbfBookHandle>(
        future: _resolvedReader.open(zbfPath),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ZbfViewerMessage(text: 'Failed to open: ${snapshot.error}');
          }
          final handle = snapshot.data;
          if (handle == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ZbfBookView(handle: handle);
        },
      ),
    );
  }
}

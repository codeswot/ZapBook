
import 'package:flutter/material.dart';
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
  });

  final String zbfPath;
  final int? initialPage;
  final String? highlightQuery;
  final ZbfReader? reader;

  @override
  Widget build(BuildContext context) {
    return _LocalReader(
      zbfPath: zbfPath,
      reader: reader ?? getIt<ZbfReader>(),
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
  late final Future<ZbfBookHandle> _futureHandle;

  @override
  void initState() {
    super.initState();
    _futureHandle = widget.reader.open(widget.zbfPath);
  }

  @override
  void dispose() {
    _futureHandle.then((handle) => handle.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ZbfBookHandle>(
      future: _futureHandle,
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



class _ViewerLoading extends StatelessWidget {
  const _ViewerLoading();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.colors.paper,
    body: const ReaderPageLoading(message: 'Opening…'),
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

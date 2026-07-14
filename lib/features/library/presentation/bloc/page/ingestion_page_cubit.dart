import 'dart:io';

import 'dart:isolate';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:collection/collection.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:zapbook/core/services/circle_store_service.dart';
import 'package:zapbook/core/services/file_hasher.dart';
import 'package:zapbook/core/data/infrastructure/file_picker_service.dart';
import 'package:zapbook/features/library/presentation/bloc/page/ingestion_page_state.dart';

@injectable
class IngestionPageCubit extends Cubit<IngestionPageState> {
  IngestionPageCubit(
    this._filePickerService,
    this._fileHasher,
    this._circleStoreService,
  ) : super(const IngestionPageIdle());

  final FilePickerService _filePickerService;
  final FileHasher _fileHasher;
  final CircleStoreService _circleStoreService;

  Future<void> pickBook() async {
    emit(const IngestionPagePicking());
    try {
      final file = await _filePickerService.pickBook();
      if (file != null) {
        final hash = await _fileHasher.sha256OfFile(file);
        final existing = _circleStoreService.currentCircles.firstWhereOrNull(
          (c) => c.contentHash == hash,
        );

        if (existing != null) {
          emit(
            IngestionPageError(
              '“${existing.title}” is already in your library',
            ),
          );
          emit(const IngestionPageIdle());
          return;
        }

        final rawTitle = file.path.split(Platform.pathSeparator).last;
        final cleanTitle = _sanitizeTitle(rawTitle);

        String? extractedTitle;
        String? extractedAuthor;

        if (file.path.toLowerCase().endsWith('.pdf')) {
          final metadata = await Isolate.run(() {
            try {
              final doc = PdfDocument(inputBytes: file.readAsBytesSync());
              final info = doc.documentInformation;
              final author = info.author.trim();
              final title = info.title.trim();
              doc.dispose();
              return {
                'author': author.isEmpty || author.toLowerCase() == 'unknown'
                    ? null
                    : author,
                'title': title.isEmpty ? null : title,
              };
            } catch (_) {
              return <String, String?>{};
            }
          });
          extractedTitle = metadata['title'];
          extractedAuthor = metadata['author'];
        }

        final finalTitle = extractedTitle ?? cleanTitle;
        emit(IngestionPageFilePicked(file, finalTitle, hash, extractedAuthor));
        emit(const IngestionPageIdle());
      } else {
        emit(const IngestionPageIdle());
      }
    } catch (e) {
      emit(IngestionPageError(e.toString()));
      emit(const IngestionPageIdle());
    }
  }

  String _sanitizeTitle(String name) {
    String stripped = name;
    final allowedExtensions = ['pdf', 'epub'];
    final lower = name.toLowerCase();
    for (final ext in allowedExtensions) {
      if (lower.endsWith('.$ext')) {
        stripped = name.substring(0, name.length - ext.length - 1);
        break;
      }
    }
    var clean = stripped.replaceAll(RegExp(r'[_+\-]'), ' ');
    clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return 'Untitled';
    return clean
        .split(' ')
        .map(
          (w) => w.isEmpty
              ? ''
              : w[0].toUpperCase() + w.substring(1).toLowerCase(),
        )
        .join(' ');
  }
}

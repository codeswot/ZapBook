import 'dart:async';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/core/domain/ingestion_progress.dart';
import 'package:zapbook/core/domain/ingestion_stage.dart';
import 'package:zapbook/core/domain/book_ingestion_repository.dart';
import 'package:zapbook/core/data/library_file_store.dart';
import 'package:zapbook/core/data/search/book_search_index.dart';
import 'package:zapbook/core/data/search/book_vector_index.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/book_extractor.dart';

import 'package:zapbook/core/domain/wizard_data.dart';

@LazySingleton(as: BookIngestionRepository)
final class BookIngestionRepositoryImpl implements BookIngestionRepository {
  BookIngestionRepositoryImpl({
    required this._extractors,
    required this._fileStore,
    required this._searchIndex,
    required this._vectorIndex,
    this._writer = const ZbfWriter(),
  });

  final List<BookExtractor> _extractors;
  final LibraryFileStore _fileStore;
  final BookSearchIndex _searchIndex;
  final BookVectorIndex _vectorIndex;
  final ZbfWriter _writer;

  @override
  Stream<IngestionProgress> ingest(
    File file, {
    Future<WizardData>? wizardDataFuture,
  }) async* {
    final extractor = _extractorFor(file);
    if (extractor == null) {
      yield IngestionProgress.failed('Unsupported file: ${file.path}');
      return;
    }

    try {
      ZbfBook? book;
      await for (final progress in extractor.extract(
        file,
        wizardDataFuture: wizardDataFuture,
      )) {
        if (progress.stage == IngestionStage.error) {
          yield progress;
          return;
        }
        if (progress.stage == IngestionStage.complete &&
            progress.result != null) {
          book = progress.result;
          break;
        }
        yield progress;
      }
      if (book == null) {
        yield IngestionProgress.failed('Extraction produced no book');
        return;
      }
      book = await _stashSourceForAi(book, file);
      yield IngestionProgress.writing('Writing ${book.manifest.title}');
      final zbfFile = await _fileStore.zbfFile(book.manifest.id);
      await zbfFile.parent.create(recursive: true);
      final path = await _writer.write(book, zbfFile.path);
      unawaited(_searchIndex.ensureIndexed(book.manifest.id, path));
      unawaited(_vectorIndex.ensureEmbedded(book.manifest.id, path));
      yield IngestionProgress.written(result: book, zbfPath: path);
    } on Exception catch (error) {
      yield IngestionProgress.failed(error.toString());
    }
  }

  Future<ZbfBook> _stashSourceForAi(ZbfBook book, File file) async {
    if (book.manifest.sourceFormat != BookSourceFormat.pdf) {
      return book;
    }
    final sourceBytes = await file.readAsBytes();
    return book.copyWith(
      assets: {...book.assets, AssetNaming.sourceDocument: sourceBytes},
    );
  }

  BookExtractor? _extractorFor(File file) {
    for (final extractor in _extractors) {
      if (extractor.supports(file)) {
        return extractor;
      }
    }
    return null;
  }
}

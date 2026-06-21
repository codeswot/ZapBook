import 'dart:async';
import 'dart:io';

import 'package:ulid/ulid.dart';

import 'package:injectable/injectable.dart';
import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/core/domain/ingestion_progress.dart';
import 'package:zapbook/core/domain/ingestion_stage.dart';
import 'package:zapbook/core/domain/book_ingestion_repository.dart';
import 'package:zapbook/core/data/library_file_store.dart';
import 'package:zapbook/core/data/search/book_search_index.dart';
import 'package:zapbook/core/data/search/book_vector_index.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/book_extractor.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/pdf_extractor.dart';

import 'package:logging/logging.dart';

import 'package:zapbook/core/domain/wizard_data.dart';

@LazySingleton(as: BookIngestionRepository)
final class BookIngestionRepositoryImpl implements BookIngestionRepository {
  static final _log = Logger('BookIngestionRepositoryImpl');

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
      final bookId = Ulid().toString();
      final zbfDir = await _fileStore.bookDir(bookId);

      ZbfBook? book;
      await for (final progress in extractor.extract(
        file,
        bookId: bookId,
        outputDirectory: zbfDir.path,
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
      final path = await _writer.write(book, zbfDir.path);

      if (extractor is PdfExtractor) {
        unawaited(
          _continuePdfExtraction(extractor, file, book, path, zbfDir.path),
        );
      } else {
        unawaited(_searchIndex.ensureIndexed(book.manifest.id, path));
        unawaited(_vectorIndex.ensureEmbedded(book.manifest.id, path));
      }

      yield IngestionProgress.written(result: book, zbfPath: path);
    } on Exception catch (error) {
      yield IngestionProgress.failed(error.toString());
    }
  }

  Future<ZbfBook> _stashSourceForAi(ZbfBook book, File file) async {
    final extension = file.path.toLowerCase().endsWith('.pdf')
        ? '.pdf'
        : '.epub';
    return book.copyWith(
      fileAssets: {
        ...book.fileAssets,
        AssetNaming.originalDocument(extension): file.path,
      },
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

  Future<void> _continuePdfExtraction(
    PdfExtractor extractor,
    File file,
    ZbfBook book,
    String zbfPath,
    String zbfDir,
  ) async {
    try {
      await extractor.extractRemainingInBackground(
        file.path,
        zbfDir,
        book.manifest.title,
      );
      await _searchIndex.ensureIndexed(book.manifest.id, zbfPath);
      await _vectorIndex.ensureEmbedded(book.manifest.id, zbfPath);
    } catch (e, st) {
      _log.severe(
        'Background extraction failed for ${book.manifest.id}',
        e,
        st,
      );
    }
  }
}

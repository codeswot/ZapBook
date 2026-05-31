import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/features/book_ingestion/domain/entities/ingestion_progress.dart';
import 'package:zapbook/features/book_ingestion/domain/enums/ingestion_stage.dart';
import 'package:zapbook/features/book_ingestion/domain/repositories/book_ingestion_repository.dart';
import 'package:zapbook/features/book_ingestion/data/documents_directory.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/book_extractor.dart';

import 'package:zapbook/features/book_ingestion/domain/entities/wizard_data.dart';

@LazySingleton(as: BookIngestionRepository)
final class BookIngestionRepositoryImpl implements BookIngestionRepository {
  BookIngestionRepositoryImpl({
    required this._extractors,
    required this._documentsDirectory,
    this._writer = const ZbfWriter(),
    this._reader = const ZbfReader(),
  });

  final List<BookExtractor> _extractors;
  final DocumentsDirectory _documentsDirectory;
  final ZbfWriter _writer;
  final ZbfReader _reader;

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
      final directory = await _documentsDirectory.resolve();
      final path = await _writer.write(book, directory);
      yield IngestionProgress.written(result: book, zbfPath: path);
    } on Object catch (error) {
      yield IngestionProgress.failed(error.toString());
    }
  }

  @override
  Future<List<BookManifest>> getIngestedBooks() async {
    final directory = await _documentsDirectory.resolve();
    if (!directory.existsSync()) {
      return const [];
    }
    final manifests = <BookManifest>[];
    for (final entity in directory.listSync()) {
      if (entity is File && entity.path.toLowerCase().endsWith('.zbf')) {
        manifests.add(await _reader.readManifest(entity.path));
      }
    }
    return manifests;
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

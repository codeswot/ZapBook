import 'dart:io';
import 'dart:typed_data';

import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/core/domain/ingestion_progress.dart';
import 'package:zapbook/features/book_ingestion/data/cover/canvas_cover_generator.dart';
import 'package:zapbook/features/book_ingestion/data/cover/cover_generator.dart';
import 'package:zapbook/features/book_ingestion/data/support/parsed_content.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/book_extractor.dart';

import 'package:zapbook/core/domain/wizard_data.dart';

abstract base class IsolateBookExtractor implements BookExtractor {
  IsolateBookExtractor({
    CoverGenerator? coverGenerator,
    this._assembler = const ZbfAssembler(),
  }) : _coverGenerator = coverGenerator ?? const CanvasCoverGenerator();

  final CoverGenerator _coverGenerator;
  final ZbfAssembler _assembler;

  String get fileExtension;

  Future<ParsedContent> parse(Uint8List bytes, String title);

  @override
  bool supports(File file) => file.path.toLowerCase().endsWith(fileExtension);

  @override
  Stream<IngestionProgress> extract(
    File file, {
    Future<WizardData>? wizardDataFuture,
  }) async* {
    final title = _titleFromPath(file.path);
    yield IngestionProgress.fileSelected(title);

    final bytes = await file.readAsBytes();
    yield IngestionProgress.extracting(
      progress: 0.1,
      currentItem: 'Reading $title',
    );

    final parsed = await parse(bytes, title);
    yield IngestionProgress.extracting(
      progress: 0.85,
      currentItem: 'Parsed ${parsed.chapters.length} chapters',
    );

    yield IngestionProgress.assembling(
      'Packaging ${parsed.chapters.length} chapters',
    );

    WizardData? customData;
    if (wizardDataFuture != null) {
      customData = await wizardDataFuture;
    }

    final finalTitle = customData?.title ?? parsed.title;
    final finalCoverSource = customData?.coverImage ?? parsed.coverSource;

    final cover = await _coverGenerator.generate(
      title: finalTitle,
      sourceImage: finalCoverSource,
    );
    final finalAuthor = customData?.author ?? parsed.author;
    final finalGenre = customData?.genre;

    final book = _assembler.assemble(
      title: finalTitle,
      author: finalAuthor,
      genre: finalGenre,
      sourceFormat: format,
      chapters: parsed.chapters,
      assets: parsed.assets,
      cover: cover,
      needsAiProcessing: parsed.needsAiProcessing,
    );
    yield IngestionProgress.complete(book);
  }

  String _titleFromPath(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final lower = name.toLowerCase();
    final stripped = lower.endsWith(fileExtension)
        ? name.substring(0, name.length - fileExtension.length)
        : name;

    final rawTitle = stripped.isEmpty ? 'Untitled' : stripped;
    return _sanitizeTitle(rawTitle);
  }

  String _sanitizeTitle(String rawTitle) {
    var clean = rawTitle.replaceAll(RegExp(r'[_+\-]'), ' ');
    clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (clean.isEmpty) return 'Untitled';

    return clean
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}

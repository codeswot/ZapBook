import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/domain/ingestion_stage.dart';
import 'package:zapbook/core/domain/wizard_data.dart';
import 'package:zapbook/features/book_ingestion/data/cover/cover_generator.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/isolate_book_extractor.dart';
import 'package:zapbook/features/book_ingestion/data/support/parsed_content.dart';
import 'package:zapbook/zbf/zbf.dart';

class MockCoverGenerator extends Mock implements CoverGenerator {}

final class TestIsolateExtractor extends IsolateBookExtractor {
  TestIsolateExtractor({super.coverGenerator, super.assembler});

  @override
  String get fileExtension => '.txt';

  @override
  BookSourceFormat get format => BookSourceFormat.txt;

  @override
  Future<ParsedContent> parse(
    String filePath,
    String title,
    String circleBookId,
    String outputDirectory,
  ) async {
    return ParsedContent(
      title: title,
      author: 'Test Author',
      chapters: const [],
      assets: const {},
      needsAiProcessing: false,
      pageWords: const [250],
      skippablePages: const [],
    );
  }
}

void main() {
  group('IsolateBookExtractor', () {
    late MockCoverGenerator coverGenerator;
    late ZbfAssembler assembler;
    late TestIsolateExtractor extractor;
    late File testFile;

    setUp(() {
      coverGenerator = MockCoverGenerator();
      assembler = const ZbfAssembler();
      extractor = TestIsolateExtractor(
        coverGenerator: coverGenerator,
        assembler: assembler,
      );
      testFile = File('my_book_title.txt');
    });

    test('supports checks file extension', () {
      expect(extractor.supports(File('test.TXT')), isTrue);
      expect(extractor.supports(File('test.txt')), isTrue);
      expect(extractor.supports(File('test.epub')), isFalse);
    });

    test('extract yields progress and completes', () async {
      when(
        () => coverGenerator.generate(
          title: any(named: 'title'),
          sourceImage: any(named: 'sourceImage'),
        ),
      ).thenAnswer((_) async => Uint8List(0));

      final stream = extractor.extract(
        testFile,
        circleBookId: 'book1',
        outputDirectory: 'dir',
      );
      final events = await stream.toList();

      expect(events.length, 5);
      expect(events[0].stage, IngestionStage.fileSelected);
      expect(events[0].currentItem, 'My Book Title');

      expect(events[1].stage, IngestionStage.extracting);
      expect(events[2].stage, IngestionStage.extracting);
      expect(events[3].stage, IngestionStage.assembling);

      expect(events[4].stage, IngestionStage.complete);
      expect(events[4].result!.manifest.title, 'My Book Title');
      expect(events[4].result!.manifest.author, 'Test Author');
      expect(events[4].result!.manifest.sourceFormat, BookSourceFormat.txt);
    });

    test('extract uses wizard data if provided', () async {
      when(
        () => coverGenerator.generate(
          title: any(named: 'title'),
          sourceImage: any(named: 'sourceImage'),
        ),
      ).thenAnswer((_) async => Uint8List(0));

      final wizardDataFuture = Future.value(
        const WizardData(
          title: 'Wizard Title',
          author: 'Wizard Author',
          genre: 'Sci-Fi',
        ),
      );

      final stream = extractor.extract(
        testFile,
        circleBookId: 'book1',
        outputDirectory: 'dir',
        wizardDataFuture: wizardDataFuture,
      );
      final events = await stream.toList();

      expect(events.last.stage, IngestionStage.complete);
      expect(events.last.result!.manifest.title, 'Wizard Title');
      expect(events.last.result!.manifest.author, 'Wizard Author');
      expect(events.last.result!.manifest.genre, 'Sci-Fi');
    });
  });
}

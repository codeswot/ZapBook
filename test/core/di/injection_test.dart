import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/features/book_ingestion/data/documents_directory.dart';
import 'package:zapbook/features/book_ingestion/domain/repositories/book_ingestion_repository.dart';
import 'package:zapbook/features/book_ingestion/domain/usecases/get_ingested_books.dart';
import 'package:zapbook/features/book_ingestion/domain/usecases/ingest_book.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/ingestion_bloc.dart';

void main() {
  tearDown(() => getIt.reset());

  test('configureDependencies wires the ingestion graph', () {
    configureDependencies();

    expect(getIt<DocumentsDirectory>(), isA<DocumentsDirectory>());
    expect(getIt<BookIngestionRepository>(), isA<BookIngestionRepository>());
    expect(getIt<IngestBook>(), isA<IngestBook>());
    expect(getIt<GetIngestedBooks>(), isA<GetIngestedBooks>());
    expect(getIt<IngestionBloc>(), isA<IngestionBloc>());
  });

  test('repository is a singleton, bloc is a factory', () {
    configureDependencies();

    expect(
      identical(
        getIt<BookIngestionRepository>(),
        getIt<BookIngestionRepository>(),
      ),
      isTrue,
    );
    expect(identical(getIt<IngestionBloc>(), getIt<IngestionBloc>()), isFalse);
  });
}

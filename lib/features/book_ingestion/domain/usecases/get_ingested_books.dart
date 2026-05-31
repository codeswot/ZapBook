import 'package:injectable/injectable.dart';
import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/features/book_ingestion/domain/repositories/book_ingestion_repository.dart';

@injectable
final class GetIngestedBooks {
  const GetIngestedBooks(this._repository);

  final BookIngestionRepository _repository;

  Future<List<BookManifest>> call() => _repository.getIngestedBooks();
}

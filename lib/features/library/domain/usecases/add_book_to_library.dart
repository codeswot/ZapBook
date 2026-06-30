import 'package:injectable/injectable.dart';

import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/features/library/domain/repositories/library_repository.dart';
import 'package:zapbook/zbf/zbf.dart';

@injectable
final class AddBookToLibrary {
  const AddBookToLibrary(this._repository);

  final LibraryRepository _repository;

  Future<CircleBook> call(
    ZbfBook book,
    String zbfPath, {
    String? contentHash,
  }) =>
      _repository.addBookFromIngestion(book, zbfPath, contentHash: contentHash);
}

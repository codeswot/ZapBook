import 'package:injectable/injectable.dart';

import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/features/library/domain/repositories/library_repository.dart';

@injectable
class DeleteCircleBook {
  DeleteCircleBook(this._repository);

  final LibraryRepository _repository;

  Future<void> call(CircleBook book) async {
    await _repository.deleteBook(book);
  }
}

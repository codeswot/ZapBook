import 'package:injectable/injectable.dart';

import 'package:zapbook/features/library/domain/repositories/library_repository.dart';

@injectable
final class DeleteLibraryBook {
  const DeleteLibraryBook(this._repository);

  final LibraryRepository _repository;

  Future<void> call(String id) => _repository.deleteBook(id);
}

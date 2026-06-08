import 'package:injectable/injectable.dart';

import 'package:zapbook/features/library/domain/repositories/library_repository.dart';

@injectable
final class GetCircleAdmins {
  const GetCircleAdmins(this._repository);

  final LibraryRepository _repository;

  Future<List<String>> call(String bookId) => _repository.bookAdmins(bookId);
}

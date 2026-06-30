import 'package:injectable/injectable.dart';

import 'package:zapbook/features/library/domain/repositories/library_repository.dart';

@injectable
final class GetBookMembers {
  const GetBookMembers(this._repository);

  final LibraryRepository _repository;

  Future<List<String>> call(String bookId) => _repository.bookMembers(bookId);
}

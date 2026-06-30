import 'package:injectable/injectable.dart';

import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/features/library/domain/repositories/library_repository.dart';

@injectable
final class GetCircleBook {
  const GetCircleBook(this._repository);

  final LibraryRepository _repository;

  Future<CircleBook?> call(String id) => _repository.getBook(id);
}

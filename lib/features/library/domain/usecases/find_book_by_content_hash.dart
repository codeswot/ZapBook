import 'package:injectable/injectable.dart';

import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/features/library/domain/repositories/library_repository.dart';

@injectable
final class FindBookByContentHash {
  const FindBookByContentHash(this._repository);

  final LibraryRepository _repository;

  Future<CircleBook?> call(String contentHash) =>
      _repository.findByContentHash(contentHash);
}

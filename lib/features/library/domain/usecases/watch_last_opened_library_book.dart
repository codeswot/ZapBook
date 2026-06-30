import 'package:injectable/injectable.dart';

import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/features/library/domain/repositories/library_repository.dart';

@injectable
final class WatchLastOpenedLibraryBook {
  const WatchLastOpenedLibraryBook(this._repository);

  final LibraryRepository _repository;

  Stream<CircleBook?> call() => _repository.watchLastOpenedBook();
}

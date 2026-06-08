import 'package:injectable/injectable.dart';

import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/domain/repositories/library_repository.dart';

@injectable
final class WatchCircles {
  const WatchCircles(this._repository);

  final LibraryRepository _repository;

  Stream<List<LibraryBook>> call() => _repository.watchBooks().map(
        (books) => books.where((book) => book.isShared).toList(growable: false),
      );
}

import 'package:injectable/injectable.dart';

import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/features/library/domain/repositories/library_repository.dart';

@injectable
final class WatchCircles {
  const WatchCircles(this._repository);

  final LibraryRepository _repository;

  Stream<List<CircleBook>> call() => _repository.watchBooks().map(
    (books) => books.where((book) => book.isShared).toList(growable: false),
  );
}

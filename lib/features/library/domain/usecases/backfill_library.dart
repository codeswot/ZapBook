import 'package:injectable/injectable.dart';

import 'package:zapbook/features/library/domain/repositories/library_repository.dart';

@injectable
final class BackfillLibrary {
  const BackfillLibrary(this._repository);

  final LibraryRepository _repository;

  Future<void> call() => _repository.backfill();
}

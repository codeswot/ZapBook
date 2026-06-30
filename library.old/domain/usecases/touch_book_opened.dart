import 'package:injectable/injectable.dart';

import 'package:zapbook/features/library/domain/repositories/library_repository.dart';

@injectable
final class TouchBookOpened {
  const TouchBookOpened(this._repository);

  final LibraryRepository _repository;

  Future<void> call(String id) => _repository.touchOpened(id);
}

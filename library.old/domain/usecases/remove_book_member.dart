import 'package:injectable/injectable.dart';

import 'package:zapbook/features/library/domain/repositories/library_repository.dart';

@injectable
final class RemoveBookMember {
  const RemoveBookMember(this._repository);

  final LibraryRepository _repository;

  Future<void> call(String circleBookId, String memberNpub) =>
      _repository.removeBookMember(circleBookId, memberNpub);
}

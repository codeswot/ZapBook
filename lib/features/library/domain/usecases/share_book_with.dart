import 'package:injectable/injectable.dart';

import 'package:zapbook/features/library/domain/repositories/library_repository.dart';

@injectable
final class ShareBookWith {
  const ShareBookWith(this._repository);

  final LibraryRepository _repository;

  Future<void> call(String bookId, List<String> memberNpubs) =>
      _repository.shareBookWith(bookId, memberNpubs);
}

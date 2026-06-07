import 'package:injectable/injectable.dart';

import 'package:zapbook/features/library/domain/repositories/library_repository.dart';

@injectable
final class ShareBook {
  const ShareBook(this._repository);

  final LibraryRepository _repository;

  Future<void> call(String bookId, String memberNpub) =>
      _repository.shareBook(bookId, memberNpub);
}

import 'package:injectable/injectable.dart';

import 'package:zapbook/features/library/domain/entities/share_skip.dart';
import 'package:zapbook/features/library/domain/repositories/library_repository.dart';

@injectable
final class ShareBookWith {
  const ShareBookWith(this._repository);

  final LibraryRepository _repository;

  Future<List<ShareSkip>> call(String bookId, List<String> memberNpubs) =>
      _repository.shareBookWith(bookId, memberNpubs);
}

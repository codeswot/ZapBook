import 'package:injectable/injectable.dart';

import 'package:zapbook/features/library/domain/repositories/library_repository.dart';

@injectable
final class LeaveCircle {
  const LeaveCircle(this._repository);

  final LibraryRepository _repository;

  Future<void> call(String circleBookId) =>
      _repository.leaveCircle(circleBookId);
}

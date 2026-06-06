import 'package:injectable/injectable.dart';

import 'package:zapbook/features/profile/domain/repositories/profile_repository.dart';

@injectable
final class SignOut {
  const SignOut(this._repository);

  final ProfileRepository _repository;

  Future<void> call() => _repository.signOut();
}

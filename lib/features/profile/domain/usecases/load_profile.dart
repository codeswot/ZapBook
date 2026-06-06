import 'package:injectable/injectable.dart';

import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
import 'package:zapbook/features/profile/domain/repositories/profile_repository.dart';

@injectable
final class LoadProfile {
  const LoadProfile(this._repository);

  final ProfileRepository _repository;

  Future<UserProfile> call() => _repository.load();
}

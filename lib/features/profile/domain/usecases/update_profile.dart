import 'package:injectable/injectable.dart';

import 'package:zapbook/features/profile/domain/repositories/profile_repository.dart';

@injectable
final class UpdateProfile {
  const UpdateProfile(this._repository);

  final ProfileRepository _repository;

  Future<void> call({String? displayName, String? lud16, String? picture}) {
    return _repository.update(
      displayName: displayName,
      lud16: lud16,
      picture: picture,
    );
  }
}

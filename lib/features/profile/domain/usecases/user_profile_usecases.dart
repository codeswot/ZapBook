import 'package:injectable/injectable.dart';

import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
import 'package:zapbook/features/profile/domain/repositories/user_profile_repository.dart';

@injectable
class LoadUserProfileUseCase {
  const LoadUserProfileUseCase(this._repository);
  final UserProfileRepository _repository;
  Future<UserProfile> call(String npub) => _repository.load(npub);
}

@injectable
class ToggleFollowUseCase {
  const ToggleFollowUseCase(this._repository);
  final UserProfileRepository _repository;
  Future<void> call(String npub, bool isFollow) =>
      _repository.toggleFollow(npub, isFollow);
}

@injectable
class SendProfileZapUseCase {
  const SendProfileZapUseCase(this._repository);
  final UserProfileRepository _repository;
  Future<void> call({
    required UserProfile profile,
    required ZapGesture gesture,
    int? customSats,
    String? comment,
  }) => _repository.zap(
    profile: profile,
    gesture: gesture,
    customSats: customSats,
    comment: comment,
  );
}

import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';

abstract class UserProfileRepository {
  Future<UserProfile> load(String npub);

  Future<void> zap({
    required UserProfile profile,
    required ZapGesture gesture,
    int? customSats,
    String? comment,
  });
}

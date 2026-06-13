import 'package:zapbook/features/profile/domain/entities/user_profile.dart';

abstract interface class ProfileRepository {
  Future<UserProfile> load();

  Future<void> update({String? displayName, String? lud16, String? picture});

  Future<void> signOut();
}

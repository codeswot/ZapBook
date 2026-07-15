import 'package:zapbook/features/onboarding/domain/entities/identity_profile.dart';

abstract class IdentityRepository {
  Future<IdentityProfile?> fetchMetadata(String npub);
}

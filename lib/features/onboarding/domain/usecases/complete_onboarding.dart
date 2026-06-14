import 'package:injectable/injectable.dart';

import 'package:zapbook/core/identity/identity_repository.dart';
import 'package:zapbook/core/session/session_reloader.dart';
import 'package:zapbook/features/onboarding/domain/repositories/onboarding_repository.dart';

@injectable
final class CompleteOnboarding {
  const CompleteOnboarding(this._identity, this._onboarding, this._reloader);

  final IdentityRepository _identity;
  final OnboardingRepository _onboarding;
  final SessionReloader _reloader;

  Future<void> call({
    required String npub,
    required String nsec,
    String? displayName,
    String? lud16,
    String? picture,
  }) async {
    await _identity.persist(npub: npub, nsec: nsec);
    await _onboarding.complete();
    if (displayName != null || lud16 != null || picture != null) {
      await _onboarding.stashPendingProfile(
        displayName: displayName,
        lud16: lud16,
        picture: picture,
      );
    }
    await _reloader.reload();
  }
}

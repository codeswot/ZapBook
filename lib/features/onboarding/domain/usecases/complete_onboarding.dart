import 'package:injectable/injectable.dart';

import 'package:zapbook/core/identity/identity_repository.dart';
import 'package:zapbook/features/onboarding/domain/repositories/onboarding_repository.dart';

@injectable
final class CompleteOnboarding {
  const CompleteOnboarding(this._identity, this._onboarding);

  final IdentityRepository _identity;
  final OnboardingRepository _onboarding;

  Future<void> call({required String npub, required String nsec}) async {
    await _identity.persist(npub: npub, nsec: nsec);
    await _onboarding.complete();
  }
}

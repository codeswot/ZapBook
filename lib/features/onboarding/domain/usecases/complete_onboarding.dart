import 'package:injectable/injectable.dart';

import 'package:zapbook/core/identity/identity_repository.dart';
import 'package:zapbook/core/identity/nostr_session.dart';
import 'package:zapbook/features/onboarding/domain/repositories/onboarding_repository.dart';

@injectable
final class CompleteOnboarding {
  const CompleteOnboarding(this._identity, this._onboarding, this._session);

  final IdentityRepository _identity;
  final OnboardingRepository _onboarding;
  final NostrSession _session;

  Future<void> call({required String npub, required String nsec}) async {
    await _identity.persist(npub: npub, nsec: nsec);
    await _session.login();
    await _onboarding.complete();
  }
}

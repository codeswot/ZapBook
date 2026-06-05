import 'package:injectable/injectable.dart';

import 'package:zapbook/core/identity/identity_repository.dart';
import 'package:zapbook/features/onboarding/data/datasources/onboarding_local_datasource.dart';
import 'package:zapbook/features/onboarding/domain/repositories/onboarding_repository.dart';

@injectable
final class CompleteOnboarding {
  const CompleteOnboarding(this._identity, this._onboarding, this._local);

  final IdentityRepository _identity;
  final OnboardingRepository _onboarding;
  final OnboardingLocalDataSource _local;

  Future<void> call({
    required String npub,
    required String nsec,
    String? lightningAddress,
  }) async {
    await _identity.persist(npub: npub, nsec: nsec);
    if (lightningAddress != null && lightningAddress.isNotEmpty) {
      await _local.saveLightningAddress(lightningAddress);
    }
    await _onboarding.complete();
  }
}

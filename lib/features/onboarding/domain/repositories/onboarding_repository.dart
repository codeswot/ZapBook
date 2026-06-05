import 'package:zapbook/features/onboarding/domain/entities/onboarding_status.dart';

abstract interface class OnboardingRepository {
  OnboardingStatus status();

  Future<void> complete();
}

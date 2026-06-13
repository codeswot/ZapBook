import 'package:injectable/injectable.dart';

import 'package:zapbook/core/data/datasources/onboarding_local_datasource.dart';
import 'package:zapbook/features/onboarding/domain/entities/onboarding_status.dart';
import 'package:zapbook/features/onboarding/domain/repositories/onboarding_repository.dart';

@LazySingleton(as: OnboardingRepository)
final class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._local);

  final OnboardingLocalDataSource _local;

  @override
  OnboardingStatus status() =>
      OnboardingStatus(isComplete: _local.isComplete());

  @override
  Future<void> complete() => _local.setComplete();
}

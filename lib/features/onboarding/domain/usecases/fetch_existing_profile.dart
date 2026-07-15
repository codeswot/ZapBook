import 'package:injectable/injectable.dart';
import 'package:zapbook/features/onboarding/domain/entities/identity_profile.dart';
import 'package:zapbook/features/onboarding/domain/repositories/identity_repository.dart';

@injectable
class FetchExistingProfileUseCase {
  const FetchExistingProfileUseCase(this._repository);

  final IdentityRepository _repository;

  Future<IdentityProfile?> call(String npub) => _repository.fetchMetadata(npub);
}

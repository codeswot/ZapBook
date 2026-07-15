import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart' show Nip19;
import 'package:zapbook/core/data/infrastructure/nostr_service.dart';
import 'package:zapbook/features/onboarding/domain/entities/identity_profile.dart';
import 'package:zapbook/features/onboarding/domain/repositories/identity_repository.dart';

@Injectable(as: IdentityRepository)
class IdentityRepositoryImpl implements IdentityRepository {
  IdentityRepositoryImpl(this._nostrService);

  final NostrService _nostrService;

  @override
  Future<IdentityProfile?> fetchMetadata(String npub) async {
    final pubkey = Nip19.decode(npub);
    if (pubkey.isEmpty) return null;

    final metadata = await _nostrService
        .getMetadata(pubkey)
        .timeout(const Duration(seconds: 10));

    if (metadata != null) {
      final fetchedName = metadata.displayName ?? metadata.name;
      final hasName = fetchedName != null && fetchedName.isNotEmpty;
      return IdentityProfile(
        displayName: hasName ? fetchedName : null,
        picture: metadata.picture,
        lightningAddress: metadata.lud16,
      );
    }

    return null;
  }
}

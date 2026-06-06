import 'package:injectable/injectable.dart';
import 'package:zapbook/core/services/nostr_service.dart';

typedef ProfileMetadata = ({
  String? name,
  String? displayName,
  String? picture,
  String? lud16,
});

@lazySingleton
class ProfileRemoteDataSource {
  const ProfileRemoteDataSource(this._nostr);

  final NostrService _nostr;

  Future<ProfileMetadata?> fetchMetadata({
    required String npub,
    required String nsec,
  }) async {
    if (npub.isEmpty || nsec.isEmpty) return null;
    try {
      _nostr.initialize(nsec: nsec, npub: npub);
      final pubkey = _nostr.pubkey;
      if (pubkey == null) return null;
      final metadata = await _nostr
          .getMetadata(pubkey)
          .timeout(const Duration(seconds: 8));
      if (metadata == null) return null;
      return (
        name: metadata.name,
        displayName: metadata.displayName,
        picture: metadata.picture,
        lud16: metadata.lud16,
      );
    } on Object {
      return null;
    }
  }

  Future<void> publish({
    required String npub,
    required String nsec,
    String? displayName,
    String? lud16,
    String? picture,
  }) async {
    _nostr.initialize(nsec: nsec, npub: npub);
    await _nostr.publishMetadata(
      displayName: displayName,
      lud16: lud16,
      picture: picture,
    );
  }
}

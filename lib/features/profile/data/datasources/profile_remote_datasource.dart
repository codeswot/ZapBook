import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';
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

  Future<ProfileMetadata?> fetchMetadata({required String npub}) async {
    if (npub.isEmpty) return null;
    try {
      final pubkey = Nip19.decode(npub);
      if (pubkey.isEmpty) return null;
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
    } on Exception {
      return null;
    }
  }

  Future<void> publish({
    String? displayName,
    String? lud16,
    String? picture,
  }) async {
    await _nostr.publishMetadata(
      displayName: displayName,
      lud16: lud16,
      picture: picture,
    );
  }
}

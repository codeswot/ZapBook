import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';

import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/identity/nostr_signer_source.dart';

@LazySingleton(as: NostrSignerSource)
class LocalKeySignerSource implements NostrSignerSource {
  const LocalKeySignerSource(this._identity);

  final IdentityLocalDataSource _identity;

  @override
  Future<EventSigner?> resolve() async {
    final nsec = await _identity.readNsec();
    final npub = await _identity.readNpub();
    if (nsec == null || nsec.isEmpty || npub == null || npub.isEmpty) {
      return null;
    }

    final privateKeyHex = Nip19.decode(nsec);
    final publicKeyHex = Nip19.decode(npub);
    if (privateKeyHex.isEmpty || publicKeyHex.isEmpty) {
      return null;
    }

    return Bip340EventSigner(
      privateKey: privateKeyHex,
      publicKey: publicKeyHex,
    );
  }
}

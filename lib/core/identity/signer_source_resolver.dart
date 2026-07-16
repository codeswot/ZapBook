import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';

import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/identity/local_key_signer_source.dart';
import 'package:zapbook/core/identity/nip55_signer_source.dart';
import 'package:zapbook/core/identity/nostr_signer_source.dart';

@LazySingleton(as: NostrSignerSource)
class SignerSourceResolver implements NostrSignerSource {
  const SignerSourceResolver(this._identity, this._local, this._nip55);

  final IdentityLocalDataSource _identity;
  final LocalKeySignerSource _local;
  final Nip55SignerSource _nip55;

  @override
  Future<EventSigner?> resolve() async {
    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return null;

    final meta = await _identity.readSignerMeta(npub);
    if (meta != null && meta.isExternal) {
      return _nip55.resolve(npub, meta);
    }
    return _local.resolve();
  }
}

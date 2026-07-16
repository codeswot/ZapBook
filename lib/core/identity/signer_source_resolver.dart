import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';

import 'package:zapbook/core/identity/bunker_signer_source.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/identity/local_key_signer_source.dart';
import 'package:zapbook/core/identity/nip55_signer_source.dart';
import 'package:zapbook/core/identity/nostr_signer_source.dart';
import 'package:zapbook/core/identity/signer_meta.dart';

@LazySingleton(as: NostrSignerSource)
class SignerSourceResolver implements NostrSignerSource {
  const SignerSourceResolver(
    this._identity,
    this._local,
    this._nip55,
    this._bunker,
  );

  final IdentityLocalDataSource _identity;
  final LocalKeySignerSource _local;
  final Nip55SignerSource _nip55;
  final BunkerSignerSource _bunker;

  @override
  Future<EventSigner?> resolve() async {
    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return null;

    final meta = await _identity.readSignerMeta(npub);
    switch (meta?.type) {
      case SignerType.nip55:
        return _nip55.resolve(npub, meta!);
      case SignerType.nip46:
        final connectionJson = meta!.connectionJson;
        if (connectionJson == null) return null;
        return _bunker.resolve(connectionJson);
      case SignerType.local:
      case null:
        return _local.resolve();
    }
  }
}

import 'package:marmot_dart/marmot_dart.dart';

import 'package:zapbook/core/identity/bunker_signer_source.dart';

class ExternalSignerConnection {
  const ExternalSignerConnection({required this.npub, required this.package});

  final String npub;
  final String package;
}

abstract interface class IdentityRepository {
  Future<NostrKeypair> generate();

  Future<NostrKeypair> importFromNsec(String nsec);

  Future<bool> validateNsec(String nsec);

  Future<void> persist({required String npub, required String nsec});

  Future<void> persistExternal({required String npub, required String package});

  Future<void> persistBunker({
    required String npub,
    required String connectionJson,
  });

  Future<bool> isExternalSignerAvailable();

  Future<ExternalSignerConnection> connectExternalSigner();

  Future<BunkerConnectResult> connectBunker(String bunkerUrl);

  NostrConnectSession initiateNostrConnect({required String appName});

  Future<String?> currentNpub();

  Future<bool> hasIdentity();

  Future<void> clear();
}

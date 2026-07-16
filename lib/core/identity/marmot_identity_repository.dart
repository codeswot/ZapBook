import 'package:injectable/injectable.dart';
import 'package:marmot_dart/marmot_dart.dart';

import 'package:zapbook/core/identity/bunker_signer_source.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/identity/identity_repository.dart';
import 'package:zapbook/core/identity/nip55_signer.dart';
import 'package:zapbook/core/identity/signer_meta.dart';

@LazySingleton(as: IdentityRepository)
class MarmotIdentityRepository implements IdentityRepository {
  const MarmotIdentityRepository(this._local, this._signer, this._bunker);

  final IdentityLocalDataSource _local;
  final Nip55Signer _signer;
  final BunkerSignerSource _bunker;

  @override
  Future<NostrKeypair> generate() => MarmotIdentity.generate();

  @override
  Future<NostrKeypair> importFromNsec(String nsec) =>
      MarmotIdentity.importFromNsec(nsec);

  @override
  Future<bool> validateNsec(String nsec) => MarmotIdentity.validateNsec(nsec);

  @override
  Future<void> persist({required String npub, required String nsec}) =>
      _local.write(npub: npub, nsec: nsec);

  @override
  Future<void> persistExternal({
    required String npub,
    required String package,
  }) => _local.writeExternal(npub: npub, package: package);

  @override
  Future<void> persistBunker({
    required String npub,
    required String connectionJson,
  }) => _local.writeBunker(npub: npub, connectionJson: connectionJson);

  @override
  Future<bool> isExternalSignerAvailable() => _signer.isSignerInstalled();

  @override
  Future<ExternalSignerConnection> connectExternalSigner() async {
    final key = await _signer.getPublicKey();
    final package = key.package;
    if (package == null || package.isEmpty) {
      throw const SignerUnavailable('Signer did not return an app package');
    }
    return ExternalSignerConnection(npub: key.npub, package: package);
  }

  @override
  Future<BunkerConnectResult> connectBunker(String bunkerUrl) =>
      _bunker.connect(bunkerUrl);

  @override
  Future<String?> currentNpub() => _local.readNpub();

  @override
  Future<bool> hasIdentity() async {
    final npub = await _local.readNpub();
    if (npub == null || npub.isEmpty) return false;
    final nsec = await _local.readNsec();
    if (nsec != null && nsec.isNotEmpty) return true;
    final meta = await _local.readSignerMeta(npub);
    return meta != null && meta.isExternal;
  }

  @override
  Future<void> clear() => _local.clear();
}

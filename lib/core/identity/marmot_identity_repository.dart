import 'package:injectable/injectable.dart';
import 'package:marmot_dart/marmot_dart.dart';

import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/identity/identity_repository.dart';

@LazySingleton(as: IdentityRepository)
class MarmotIdentityRepository implements IdentityRepository {
  const MarmotIdentityRepository(this._local);

  final IdentityLocalDataSource _local;

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
  Future<String?> currentNpub() => _local.readNpub();

  @override
  Future<String?> currentNsec() => _local.readNsec();

  @override
  Future<bool> hasIdentity() async {
    final nsec = await _local.readNsec();
    return nsec != null && nsec.isNotEmpty;
  }

  @override
  Future<void> clear() => _local.clear();
}

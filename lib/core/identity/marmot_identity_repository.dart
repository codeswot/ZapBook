import 'package:injectable/injectable.dart';
import 'package:marmot_dart/marmot_dart.dart';

import 'package:zapbook/core/identity/identity_repository.dart';
import 'package:zapbook/core/services/secure_storage_service.dart';

@LazySingleton(as: IdentityRepository)
class MarmotIdentityRepository implements IdentityRepository {
  const MarmotIdentityRepository(this._storage);

  final SecureStorageService _storage;

  static const String _nsecKey = 'identity_nsec';
  static const String _npubKey = 'identity_npub';

  @override
  Future<NostrKeypair> generate() => MarmotIdentity.generate();

  @override
  Future<NostrKeypair> importFromNsec(String nsec) =>
      MarmotIdentity.importFromNsec(nsec);

  @override
  Future<bool> validateNsec(String nsec) => MarmotIdentity.validateNsec(nsec);

  @override
  Future<void> persist({required String npub, required String nsec}) async {
    await _storage.write(_nsecKey, nsec);
    await _storage.write(_npubKey, npub);
  }

  @override
  Future<String?> currentNpub() => _storage.read(_npubKey);

  @override
  Future<String?> currentNsec() => _storage.read(_nsecKey);

  @override
  Future<bool> hasIdentity() async {
    final nsec = await _storage.read(_nsecKey);
    return nsec != null && nsec.isNotEmpty;
  }
}

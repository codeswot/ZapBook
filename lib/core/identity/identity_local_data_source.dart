import 'package:injectable/injectable.dart';
import 'package:zapbook/core/services/secure_storage_service.dart';

@lazySingleton
class IdentityLocalDataSource {
  const IdentityLocalDataSource(this._storage);

  final SecureStorageService _storage;

  static const String _nsecKey = 'identity_nsec';
  static const String _npubKey = 'identity_npub';

  Future<void> write({required String npub, required String nsec}) async {
    await _storage.write(_nsecKey, nsec);
    await _storage.write(_npubKey, npub);
  }

  Future<String?> readNpub() => _storage.read(_npubKey);

  Future<String?> readNsec() => _storage.read(_nsecKey);

  Future<void> clear() async {
    await _storage.delete(_nsecKey);
    await _storage.delete(_npubKey);
  }
}

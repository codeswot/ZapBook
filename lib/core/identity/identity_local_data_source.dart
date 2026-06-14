import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:zapbook/core/identity/active_account.dart';
import 'package:zapbook/core/services/secure_storage_service.dart';

@lazySingleton
class IdentityLocalDataSource {
  const IdentityLocalDataSource(this._storage);

  final SecureStorageService _storage;

  static const String _accountsKey = 'accounts';
  static const String _activeKey = ActiveAccount.activeNpubKey;

  Future<Map<String, String>> _accounts() async {
    final raw = await _storage.read(_accountsKey);
    if (raw == null || raw.isEmpty) return <String, String>{};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v as String));
    } on Object {
      return <String, String>{};
    }
  }

  Future<void> _saveAccounts(Map<String, String> accounts) =>
      _storage.write(_accountsKey, jsonEncode(accounts));

  Future<void> addAccount({required String npub, required String nsec}) async {
    final accounts = await _accounts();
    accounts[npub] = nsec;
    await _saveAccounts(accounts);
  }

  Future<void> setActive(String npub) async {
    await _storage.write(_activeKey, npub);
    ActiveAccount.setNpub(npub);
  }

  Future<List<String>> listNpubs() async => (await _accounts()).keys.toList();

  Future<void> removeAccount(String npub) async {
    final accounts = await _accounts();
    accounts.remove(npub);
    await _saveAccounts(accounts);
    if (await readNpub() == npub) {
      await _storage.delete(_activeKey);
      ActiveAccount.setNpub(null);
    }
  }

  Future<void> write({required String npub, required String nsec}) async {
    await addAccount(npub: npub, nsec: nsec);
    await setActive(npub);
  }

  Future<String?> readNpub() => _storage.read(_activeKey);

  Future<String?> readNsec() async {
    final npub = await readNpub();
    if (npub == null) return null;
    return (await _accounts())[npub];
  }

  Future<String?> readDtag(String key) => _storage.read(ActiveAccount.key(key));

  Future<void> writeDtag(String key, String value) =>
      _storage.write(ActiveAccount.key(key), value);

  Future<void> clear() async {
    await _storage.delete(_activeKey);
    ActiveAccount.setNpub(null);
  }
}

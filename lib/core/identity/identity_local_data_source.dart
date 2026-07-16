import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:zapbook/core/identity/active_account.dart';
import 'package:zapbook/core/identity/signer_meta.dart';
import 'package:zapbook/core/data/infrastructure/secure_storage_service.dart';

@lazySingleton
class IdentityLocalDataSource {
  IdentityLocalDataSource(this._storage);

  final SecureStorageService _storage;

  static const String _accountsKey = 'accounts';
  static const String _signerMetaKey = 'signer_meta';
  static const String _activeKey = ActiveAccount.activeNpubKey;

  Map<String, String>? _cachedAccounts;
  Map<String, dynamic>? _cachedSignerMeta;

  Future<Map<String, String>> _accounts() async {
    if (_cachedAccounts != null) return Map.from(_cachedAccounts!);
    final raw = await _storage.read(_accountsKey);
    if (raw == null || raw.isEmpty) return <String, String>{};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _cachedAccounts = map.map((k, v) => MapEntry(k, v as String));
      return Map.from(_cachedAccounts!);
    } on Object {
      return <String, String>{};
    }
  }

  Future<void> _saveAccounts(Map<String, String> accounts) async {
    _cachedAccounts = Map.from(accounts);
    await _storage.write(_accountsKey, jsonEncode(accounts));
  }

  Future<Map<String, dynamic>> _signerMeta() async {
    if (_cachedSignerMeta != null) return Map.from(_cachedSignerMeta!);
    final raw = await _storage.read(_signerMetaKey);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      _cachedSignerMeta = jsonDecode(raw) as Map<String, dynamic>;
      return Map.from(_cachedSignerMeta!);
    } on Object {
      return <String, dynamic>{};
    }
  }

  Future<void> _saveSignerMeta(Map<String, dynamic> meta) async {
    _cachedSignerMeta = Map.from(meta);
    await _storage.write(_signerMetaKey, jsonEncode(meta));
  }

  Future<void> addAccount({required String npub, required String nsec}) async {
    final accounts = await _accounts();
    accounts[npub] = nsec;
    await _saveAccounts(accounts);
  }

  Future<void> addExternalAccount({
    required String npub,
    required String package,
  }) async {
    final meta = await _signerMeta();
    meta[npub] = SignerMeta(type: SignerType.nip55, package: package).toJson();
    await _saveSignerMeta(meta);
  }

  Future<SignerMeta?> readSignerMeta(String npub) async {
    final meta = await _signerMeta();
    return SignerMeta.fromJson(meta[npub]);
  }

  Future<void> setActive(String npub) async {
    await _storage.write(_activeKey, npub);
    ActiveAccount.setNpub(npub);
  }

  Future<List<String>> listNpubs() async {
    final accounts = await _accounts();
    final meta = await _signerMeta();
    return {...accounts.keys, ...meta.keys}.toList();
  }

  Future<void> removeAccount(String npub) async {
    final accounts = await _accounts();
    accounts.remove(npub);
    await _saveAccounts(accounts);

    final meta = await _signerMeta();
    if (meta.remove(npub) != null) {
      await _saveSignerMeta(meta);
    }

    if (ActiveAccount.currentNpub == npub) {
      await _storage.delete(_activeKey);
      ActiveAccount.setNpub(null);
    }
  }

  Future<void> write({required String npub, required String nsec}) async {
    await addAccount(npub: npub, nsec: nsec);
    await setActive(npub);
  }

  Future<void> writeExternal({
    required String npub,
    required String package,
  }) async {
    await addExternalAccount(npub: npub, package: package);
    await setActive(npub);
  }

  Future<String?> readNpub() async {
    if (ActiveAccount.currentNpub != null) return ActiveAccount.currentNpub;
    final npub = await _storage.read(_activeKey);
    ActiveAccount.setNpub(npub);
    return npub;
  }

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

// ignore_for_file: experimental_member_use

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:ndk/ndk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zapbook/core/services/secure_storage_service.dart';

@lazySingleton
class NwcService {
  NwcService(this._prefs, this._ndk, this._secureStorage) {
    _restore();
  }

  final SharedPreferences _prefs;
  final Ndk _ndk;
  final SecureStorageService _secureStorage;
  final _log = logging.Logger('NwcService');

  static const _connectionKey = 'nwc_connection_string';
  static const _walletNameKey = 'nwc_wallet_name';

  String? _connectionString;
  String? _walletName;
  NwcConnection? _connection;

  String? get connectionString => _connectionString;
  String? get walletName => _walletName;
  bool get isConnected => _connection != null;

  Future<void> _restore() async {
    await _migrateFromPrefs();
    _connectionString = await _secureStorage.read(_connectionKey);
    _walletName = _prefs.getString(_walletNameKey);

    final saved = _connectionString;
    if (saved == null) return;

    try {
      _connection = await _establish(saved);
      _log.info('NWC restored: $_walletName');
    } on Exception catch (error) {
      _log.warning('NWC restore failed: $error');
    }
  }

  Future<NwcConnection> _establish(String connectionString) async {
    String? error;
    final connection = await _ndk.nwc.connect(
      connectionString,
      onError: (message) => error = message,
    );

    if (error != null || connection.subscription == null) {
      await _ndk.nwc.disconnect(connection);
      throw Exception(
        'Wallet connection failed: ${error ?? 'wallet info not found'}',
      );
    }

    return connection;
  }

  Future<void> connect(String connectionString) async {
    if (isConnected) await disconnect();

    final connection = await _establish(connectionString);

    _connection = connection;
    _connectionString = connectionString;
    _walletName = _deriveName(connection);

    await _secureStorage.write(_connectionKey, connectionString);
    await _prefs.setString(_walletNameKey, _walletName!);

    _log.info('NWC connected: $_walletName');
  }

  Future<void> disconnect() async {
    final connection = _connection;
    if (connection != null) await _ndk.nwc.disconnect(connection);

    _connection = null;
    _connectionString = null;
    _walletName = null;
    await _secureStorage.delete(_connectionKey);
    await _prefs.remove(_walletNameKey);
  }

  Future<void> _migrateFromPrefs() async {
    final legacy = _prefs.getString(_connectionKey);
    if (legacy == null) return;
    await _secureStorage.write(_connectionKey, legacy);
    await _prefs.remove(_connectionKey);
  }

  String _deriveName(NwcConnection connection) {
    final relays = connection.uri.relays;
    if (relays.isEmpty) return 'Wallet';

    final host = Uri.tryParse(relays.first)?.host ?? '';
    if (host.isEmpty) return 'Wallet';

    final parts = host.split('.');
    return parts.length >= 2 ? parts[parts.length - 2] : parts.first;
  }
}

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:ndk/ndk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zapbook/core/services/nostr_service.dart';

@lazySingleton
class NwcService {
  NwcService(this._prefs, this._ndk, this._nostr) {
    _loadFromStorage();
  }

  final SharedPreferences _prefs;
  final Ndk _ndk;
  final NostrService _nostr;
  final _log = logging.Logger('NwcService');

  static const _connectionKey = 'nwc_connection_string';
  static const _walletNameKey = 'nwc_wallet_name';

  String? _connectionString;
  String? _walletName;
  BunkerConnection? _connection;

  String? get connectionString => _connectionString;
  String? get walletName => _walletName;
  bool get isConnected => _connection != null;

  void _loadFromStorage() {
    _connectionString = _prefs.getString(_connectionKey);
    _walletName = _prefs.getString(_walletNameKey);
  }

  Future<void> connect(String connectionString) async {
    if (!_nostr.isInitialized) {
      throw StateError('NostrService not initialized. Log in first.');
    }

    if (isConnected) await disconnect();

    final connection = await _ndk.accounts.loginWithBunkerUrl(
      bunkerUrl: connectionString,
      bunkers: _ndk.bunkers,
    );
    if (connection == null) {
      throw Exception('Failed to establish bunker connection');
    }

    _connection = connection;
    _connectionString = connectionString;
    await _prefs.setString(_connectionKey, connectionString);

    final uri = Uri.tryParse(connectionString);
    _walletName =
        uri?.queryParameters['relay']
            ?.replaceAll('wss://', '')
            .replaceAll('ws://', '')
            .split('.')
            .first ??
        'Wallet';
    await _prefs.setString(_walletNameKey, _walletName!);

    _log.info('NWC connected: $_walletName');
  }

  Future<void> disconnect() async {
    _connection = null;
    _connectionString = null;
    _walletName = null;
    await _prefs.remove(_connectionKey);
    await _prefs.remove(_walletNameKey);
  }
}

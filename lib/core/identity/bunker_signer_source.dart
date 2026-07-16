import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:zapbook/core/identity/signer_meta.dart';

class BunkerConnectResult {
  const BunkerConnectResult({required this.npub, required this.connectionJson});

  final String npub;
  final String connectionJson;
}

@lazySingleton
class BunkerSignerSource {
  const BunkerSignerSource(this._ndk);

  final Ndk _ndk;

  Future<EventSigner?> resolve(String connectionJson) async {
    final connection = _decode(connectionJson);
    if (connection == null) return null;
    final signer = _ndk.bunkers.createSigner(
      connection,
      authCallback: _openAuthUrl,
    );
    await signer.getPublicKeyAsync();
    return signer;
  }

  Future<BunkerConnectResult> connect(String bunkerUrl) async {
    final trimmed = bunkerUrl.trim();
    if (!trimmed.startsWith('bunker://')) {
      throw const SignerMalformed('Enter a valid bunker:// connection link');
    }

    final BunkerConnection? connection;
    try {
      connection = await _ndk.bunkers.connectWithBunkerUrl(
        trimmed,
        authCallback: _openAuthUrl,
      );
    } on Object catch (error) {
      throw SignerUnavailable(error.toString());
    }
    if (connection == null) {
      throw const SignerUnavailable('Bunker did not confirm the connection');
    }

    final signer = _ndk.bunkers.createSigner(
      connection,
      authCallback: _openAuthUrl,
    );
    final raw = await signer.getPublicKeyAsync();
    final npub = raw.startsWith('npub') ? raw : Nip19.encodePubKey(raw);
    return BunkerConnectResult(
      npub: npub,
      connectionJson: jsonEncode(connection.toJson()),
    );
  }

  BunkerConnection? _decode(String connectionJson) {
    try {
      final map = jsonDecode(connectionJson) as Map<String, dynamic>;
      return BunkerConnection.fromJson(map);
    } on Object {
      return null;
    }
  }

  void _openAuthUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
  }
}

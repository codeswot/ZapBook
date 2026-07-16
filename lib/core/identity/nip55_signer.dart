import 'dart:io';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';

import 'package:zapbook/core/identity/signer_meta.dart';

class Nip55PublicKey {
  const Nip55PublicKey({
    required this.npub,
    required this.hex,
    required this.package,
  });

  final String npub;
  final String hex;
  final String? package;
}

@lazySingleton
class Nip55Signer {
  const Nip55Signer();

  static const _channel = MethodChannel('zapbook/nip55');

  Future<bool> isSignerInstalled() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isSignerInstalled') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<Nip55PublicKey> getPublicKey() async {
    final result = await _invokeMap('getPublicKey');
    final raw = result['pubkey'] as String?;
    if (raw == null || raw.isEmpty) {
      throw const SignerMalformed('Empty public key');
    }
    final package = result['package'] as String?;
    final npub = raw.startsWith('npub') ? raw : Nip19.encodePubKey(raw);
    final hex = raw.startsWith('npub') ? Nip19.decode(raw) : raw;
    return Nip55PublicKey(npub: npub, hex: hex, package: package);
  }

  Future<String> signEvent({
    required String eventJson,
    required String currentUserHex,
    required String package,
  }) =>
      _invokeString('signEvent', {
        'eventJson': eventJson,
        'currentUser': currentUserHex,
        'package': package,
      });

  Future<String> nip44Encrypt({
    required String plaintext,
    required String counterpartyHex,
    required String currentUserHex,
    required String package,
  }) =>
      _invokeString('nip44Encrypt', {
        'payload': plaintext,
        'pubkey': counterpartyHex,
        'currentUser': currentUserHex,
        'package': package,
      });

  Future<String> nip44Decrypt({
    required String ciphertext,
    required String counterpartyHex,
    required String currentUserHex,
    required String package,
  }) =>
      _invokeString('nip44Decrypt', {
        'payload': ciphertext,
        'pubkey': counterpartyHex,
        'currentUser': currentUserHex,
        'package': package,
      });

  Future<String> nip04Encrypt({
    required String plaintext,
    required String counterpartyHex,
    required String currentUserHex,
    required String package,
  }) =>
      _invokeString('nip04Encrypt', {
        'payload': plaintext,
        'pubkey': counterpartyHex,
        'currentUser': currentUserHex,
        'package': package,
      });

  Future<String> nip04Decrypt({
    required String ciphertext,
    required String counterpartyHex,
    required String currentUserHex,
    required String package,
  }) =>
      _invokeString('nip04Decrypt', {
        'payload': ciphertext,
        'pubkey': counterpartyHex,
        'currentUser': currentUserHex,
        'package': package,
      });

  Future<Map<String, dynamic>> _invokeMap(String method, [Map<String, dynamic>? args]) async {
    if (!Platform.isAndroid) throw const SignerNotInstalled();
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(method, args);
      if (result == null) throw const SignerMalformed('Empty signer response');
      return result;
    } on PlatformException catch (e) {
      throw Nip55Exception.fromCode(e.code, e.message);
    }
  }

  Future<String> _invokeString(String method, Map<String, dynamic> args) async {
    if (!Platform.isAndroid) throw const SignerNotInstalled();
    try {
      final result = await _channel.invokeMethod<String>(method, args);
      if (result == null || result.isEmpty) {
        throw const SignerMalformed('Empty signer response');
      }
      return result;
    } on PlatformException catch (e) {
      throw Nip55Exception.fromCode(e.code, e.message);
    }
  }
}

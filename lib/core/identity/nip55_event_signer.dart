import 'dart:convert';

import 'package:ndk/ndk.dart';

import 'package:zapbook/core/identity/nip55_signer.dart';

class Nip55EventSigner implements EventSigner {
  Nip55EventSigner(this._channel, this._accountHex, this._package);

  final Nip55Signer _channel;
  final String _accountHex;
  final String _package;

  @override
  String getPublicKey() => _accountHex;

  @override
  bool canSign() => true;

  @override
  Future<Nip01Event> sign(Nip01Event event) async {
    final unsigned = jsonEncode({
      'id': event.id,
      'pubkey': event.pubKey,
      'created_at': event.createdAt,
      'kind': event.kind,
      'tags': event.tags,
      'content': event.content,
    });

    final response = await _channel.signEvent(
      eventJson: unsigned,
      currentUserHex: _accountHex,
      package: _package,
    );

    final map = _tryDecode(response);
    if (map == null) {
      return event.copyWith(sig: response);
    }

    final tags = (map['tags'] as List)
        .map((t) => (t as List).map((e) => e.toString()).toList())
        .toList();
    return Nip01Event(
      id: map['id'] as String?,
      pubKey: map['pubkey'] as String,
      kind: (map['kind'] as num).toInt(),
      tags: tags,
      content: map['content'] as String,
      sig: map['sig'] as String?,
      createdAt: (map['created_at'] as num).toInt(),
    );
  }

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) =>
      _channel.nip44Encrypt(
        plaintext: plaintext,
        counterpartyHex: recipientPubKey,
        currentUserHex: _accountHex,
        package: _package,
      );

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) =>
      _channel.nip44Decrypt(
        ciphertext: ciphertext,
        counterpartyHex: senderPubKey,
        currentUserHex: _accountHex,
        package: _package,
      );

  @override
  Future<String?> encrypt(String msg, String destPubKey, {String? id}) =>
      _channel.nip04Encrypt(
        plaintext: msg,
        counterpartyHex: destPubKey,
        currentUserHex: _accountHex,
        package: _package,
      );

  @override
  Future<String?> decrypt(String msg, String destPubKey, {String? id}) =>
      _channel.nip04Decrypt(
        ciphertext: msg,
        counterpartyHex: destPubKey,
        currentUserHex: _accountHex,
        package: _package,
      );

  @override
  List<PendingSignerRequest> get pendingRequests => const [];

  @override
  Stream<List<PendingSignerRequest>> get pendingRequestsStream =>
      const Stream.empty();

  @override
  bool cancelRequest(String requestId) => false;

  @override
  Future<void> dispose() async {}

  Map<String, dynamic>? _tryDecode(String value) {
    try {
      final decoded = jsonDecode(value);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}

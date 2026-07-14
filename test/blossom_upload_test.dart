import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ndk/ndk.dart';
import 'package:crypto/crypto.dart';

void main() async {
  final bytes = utf8.encode(
    'test blossom upload concurrency with missing u tag',
  );
  final hash = sha256.convert(bytes).toString();

  final signer = const Bip340EventSignerFactory().createWithNewKeyPair();
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  final event = Nip01Event(
    pubKey: signer.getPublicKey(),
    kind: 24242,
    content: 'upload',
    createdAt: now,
    tags: [
      ['t', 'upload'],
      ['x', hash],
      ['expiration', '${now + 3600}'],
    ],
  );

  final signed = await signer.sign(event);
  final jsonStr = jsonEncode({
    'id': signed.id,
    'pubkey': signed.pubKey,
    'created_at': signed.createdAt,
    'kind': signed.kind,
    'tags': signed.tags,
    'content': signed.content,
    'sig': signed.sig,
  });
  final authHeader = 'Nostr ${base64Encode(utf8.encode(jsonStr))}';

  final res1 = await http.put(
    Uri.parse('https://cdn.hzrd149.com/upload'),
    headers: {'Authorization': authHeader, 'User-Agent': 'Test'},
    body: bytes,
  );
  if (kDebugMode) {
    print("hzrd149.com: ${res1.statusCode} ${res1.body}");
  }

  if (kDebugMode) {
    print("Trying upload to https://nostr.download...");
  }
  final res2 = await http.put(
    Uri.parse('https://nostr.download/upload'),
    headers: {'Authorization': authHeader, 'User-Agent': 'Test'},
    body: bytes,
  );
  if (kDebugMode) {
    print("nostr.download: ${res2.statusCode} ${res2.body}");
  }
}

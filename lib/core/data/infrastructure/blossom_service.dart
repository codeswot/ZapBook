import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:ndk/ndk.dart';

class BlossomException implements Exception {
  const BlossomException(this.message, [this.details = const []]);

  final String message;
  final List<String> details;

  @override
  String toString() =>
      details.isEmpty ? message : '$message: ${details.join('; ')}';
}

typedef _UploadAttempt = ({String? url, String? error});

@lazySingleton
class BlossomService {
  BlossomService(this._ndk);

  final Ndk _ndk;

  final _log = logging.Logger('BlossomService');
  final http.Client _http = http.Client();

  static const List<String> servers = [
    'https://cdn.hzrd149.com',
    'https://nostr.download',
  ];

  static const int maxDownloadBytes = 150 * _bytesPerMegabyte;
  static const int _bytesPerMegabyte = 1024 * 1024;
  static const int _blossomAuthKind = 24242;
  static const String _uploadAction = 'upload';
  static const String _uploadEndpoint = 'upload';
  static const String _defaultMimeType = 'application/octet-stream';
  static const String _authScheme = 'Nostr';
  static const Set<int> _uploadSuccessCodes = {200, 201};
  static const Duration _authTtl = Duration(hours: 1);
  static const Duration _uploadTimeout = Duration(minutes: 2);
  static const Duration _responseTimeout = Duration(seconds: 30);

  static final RegExp _sha256InUrl = RegExp(
    r'/([a-fA-F0-9]{64})(?![a-fA-F0-9])',
  );

  static const Map<String, String> _baseHeaders = {
    'User-Agent':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
  };

  Future<String> upload(
    Uint8List bytes, {
    String mimeType = _defaultMimeType,
  }) async {
    final hash = sha256.convert(bytes).toString();
    final authHeader = await _authorizationHeader(
      action: _uploadAction,
      hash: hash,
    );

    final attempts = await Future.wait(
      servers.map(
        (server) => _uploadToServer(
          server: server,
          bytes: bytes,
          mimeType: mimeType,
          authHeader: authHeader,
          hash: hash,
        ),
      ),
    );

    final url = attempts.map((attempt) => attempt.url).nonNulls.firstOrNull;
    if (url == null) {
      throw BlossomException(
        'Upload failed on all servers',
        attempts.map((attempt) => attempt.error).nonNulls.toList(),
      );
    }

    _log.info('Blossom upload ok: $url');
    return url;
  }

  Future<Uint8List> download(String url) async {
    final expectedHash = _sha256InUrl.firstMatch(url)?.group(1)?.toLowerCase();

    if (expectedHash == null) {
      return _fetch(Uri.parse(url), expectedHash: null);
    }

    final candidates = <String>{
      url,
      ...servers.map((server) => '$server/$expectedHash'),
    };

    final errors = <String>[];
    for (final candidate in candidates) {
      try {
        return await _fetch(Uri.parse(candidate), expectedHash: expectedHash);
      } catch (e) {
        errors.add('$candidate: $e');
      }
    }

    throw BlossomException('Download failed for $expectedHash', errors);
  }

  Future<_UploadAttempt> _uploadToServer({
    required String server,
    required Uint8List bytes,
    required String mimeType,
    required String authHeader,
    required String hash,
  }) async {
    try {
      final response = await _http
          .put(
            Uri.parse('$server/$_uploadEndpoint'),
            headers: {
              ..._baseHeaders,
              'Authorization': authHeader,
              'Content-Type': mimeType,
            },
            body: bytes,
          )
          .timeout(_uploadTimeout);

      if (_uploadSuccessCodes.contains(response.statusCode)) {
        return (url: _descriptorUrl(response.body, server, hash), error: null);
      }

      final reason = response.headers['x-reason'] ?? '';
      return (
        url: null,
        error: '$server: HTTP ${response.statusCode} $reason'.trim(),
      );
    } catch (e) {
      return (url: null, error: '$server: $e');
    }
  }

  Future<Uint8List> _fetch(Uri uri, {required String? expectedHash}) async {
    final request = http.Request('GET', uri)..headers.addAll(_baseHeaders);
    final response = await _http.send(request).timeout(_responseTimeout);

    if (response.statusCode != 200) {
      await response.stream.drain<void>().catchError((_) {});
      throw BlossomException('HTTP ${response.statusCode}');
    }

    final declaredLength = int.tryParse(
      response.headers['content-length'] ?? '',
    );
    if (declaredLength != null) {
      _ensureWithinLimit(declaredLength);
    }

    final builder = BytesBuilder(copy: false);
    await for (final chunk in response.stream) {
      builder.add(chunk);
      _ensureWithinLimit(builder.length);
    }

    final bytes = builder.takeBytes();
    if (expectedHash != null) {
      final actualHash = sha256.convert(bytes).toString();
      if (actualHash != expectedHash) {
        throw const BlossomException('sha256 mismatch');
      }
    }
    return bytes;
  }

  void _ensureWithinLimit(int length) {
    if (length > maxDownloadBytes) {
      throw BlossomException(
        'Blob exceeds ${maxDownloadBytes ~/ _bytesPerMegabyte}MB limit',
      );
    }
  }

  Future<String> _authorizationHeader({
    required String action,
    required String hash,
  }) async {
    final signer = _resolveSigner();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final event = Nip01Event(
      pubKey: signer.getPublicKey(),
      kind: _blossomAuthKind,
      content: action,
      createdAt: now,
      tags: [
        ['t', action],
        ['x', hash],
        ['expiration', '${now + _authTtl.inSeconds}'],
      ],
    );
    final signed = await signer.sign(event);

    final json = jsonEncode({
      'id': signed.id,
      'pubkey': signed.pubKey,
      'created_at': signed.createdAt,
      'kind': signed.kind,
      'tags': signed.tags,
      'content': signed.content,
      'sig': signed.sig,
    });
    return '$_authScheme ${base64Encode(utf8.encode(json))}';
  }

  EventSigner _resolveSigner() {
    final account = _ndk.accounts.getLoggedAccount();
    if (account != null && account.signer.canSign()) {
      return account.signer;
    }
    return const Bip340EventSignerFactory().createWithNewKeyPair();
  }

  String _descriptorUrl(String responseBody, String server, String hash) {
    try {
      final descriptor = jsonDecode(responseBody);
      if (descriptor is Map<String, dynamic>) {
        final url = descriptor['url'];
        if (url is String && url.isNotEmpty) {
          return url;
        }
      }
    } catch (e, st) {
      _log.warning('failed _descriptorUrl', e, st);
    }
    return '$server/$hash';
  }
}

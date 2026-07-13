import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:ndk/ndk.dart';

@lazySingleton
class BlossomService {
  BlossomService(this._ndk);

  final Ndk _ndk;

  final _log = logging.Logger('BlossomService');
  final http.Client _httpClient = http.Client();

  static const List<String> servers = [
    'https://cdn.satellite.earth',
    'https://blossom.nostr.build',
  ];

  Future<String> upload(
    Uint8List bytes, {
    String mimeType = 'application/octet-stream',
  }) async {
    final account = _ndk.accounts.getLoggedAccount();

    for (final server in servers) {
      try {
        final url = '$server/upload';
        final request = http.Request('PUT', Uri.parse(url));
        request.bodyBytes = bytes;

        if (account != null && account.signer.canSign()) {
          final payloadHash = sha256.convert(bytes).toString();
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          final expiration = now + 600;

          final authEvent = Nip01Event(
            pubKey: account.pubkey,
            kind: 24242,
            tags: [
              ['u', url],
              ['method', 'PUT'],
              ['t', 'upload'],
              ['x', payloadHash],
              ['expiration', expiration.toString()],
            ],
            content: 'Upload blossom',
            createdAt: now,
          );
          final signed = await account.signer.sign(authEvent);
          final authJson = jsonEncode({
            'id': signed.id,
            'pubkey': signed.pubKey,
            'created_at': signed.createdAt,
            'kind': signed.kind,
            'tags': signed.tags,
            'content': signed.content,
            'sig': signed.sig,
          });

          final encodedAuth = base64Encode(utf8.encode(authJson));
          request.headers['Authorization'] = 'Nostr $encodedAuth';
        }

        request.headers['User-Agent'] =
            'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1';

        if (mimeType.isNotEmpty) {
          request.headers['Content-Type'] = mimeType;
        }

        final response = await _httpClient.send(request);
        if (response.statusCode == 200 || response.statusCode == 201) {
          final body = await response.stream.bytesToString();
          final map = jsonDecode(body) as Map<String, dynamic>;
          final uploadedUrl = map['url'] as String;
          _log.info('Uploaded to $server OK');
          return uploadedUrl;
        } else {
          final body = await response.stream.bytesToString();
          _log.warning(
            'Upload failed to $server: ${response.statusCode} - $body',
          );
        }
      } catch (e, st) {
        _log.warning('Upload failed to $server', e, st);
      }
    }

    throw Exception('All blossom servers failed to upload');
  }

  static const int maxDownloadBytes = 150 * 1024 * 1024;

  Future<Uint8List> download(String url) async {
    final sha256Match = RegExp(r'/([a-fA-F0-9]{64})(?:/|$)').firstMatch(url);
    final expectedSha256 = sha256Match?.group(1);

    if (expectedSha256 == null) {
      final response = await _ndk.files.download(url: url, serverUrls: servers);
      if (response.data.length > maxDownloadBytes) {
        throw Exception(
          'Blossom blob exceeds ${maxDownloadBytes ~/ (1024 * 1024)}MB limit',
        );
      }
      return response.data;
    }

    final allUrlsToTry = {
      url,
      ...servers.map((s) => '$s/$expectedSha256'),
    }.toList();

    for (final tryUrl in allUrlsToTry) {
      try {
        final request = http.Request('GET', Uri.parse(tryUrl));
        final response = await _httpClient.send(request);

        if (response.statusCode == 200 || response.statusCode == 206) {
          final contentType = response.headers['content-type'] ?? '';
          if (contentType.contains('text/html')) {
            _log.warning('Server returned HTML, skipping $tryUrl');
            continue;
          }

          final declaredLength = int.tryParse(
            response.headers['content-length'] ?? '',
          );
          if (declaredLength != null && declaredLength > maxDownloadBytes) {
            throw Exception(
              'File too large: ${declaredLength ~/ (1024 * 1024)}MB',
            );
          }

          final byteBuilder = BytesBuilder();
          final hashSink = AccumulatorSink<Digest>();
          final hashInput = sha256.startChunkedConversion(hashSink);

          await for (final chunk in response.stream) {
            byteBuilder.add(chunk);
            hashInput.add(chunk);

            if (byteBuilder.length > maxDownloadBytes) {
              throw Exception('Streamed file exceeded size limit');
            }
          }

          hashInput.close();
          final hash = hashSink.events.single.toString();

          if (hash == expectedSha256) {
            return byteBuilder.takeBytes();
          } else {
            _log.warning('Hash mismatch for $tryUrl');
          }
        }
      } catch (e, st) {
        _log.warning('Failed to download from $tryUrl', e, st);
      }
    }

    throw Exception('Failed to download valid blob for $url from any server');
  }
}

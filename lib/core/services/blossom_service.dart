import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:ndk/domain_layer/entities/ndk_file.dart';
import 'package:ndk/ndk.dart';

@lazySingleton
class BlossomService {
  BlossomService(this._ndk);

  final Ndk _ndk;
  final _log = logging.Logger('BlossomService');

  static const List<String> servers = [
    'https://blossom.primal.net',
    'https://blossom.nostr.build',
    'https://yondar.me',
  ];

  Future<String> upload(
    Uint8List bytes, {
    String mimeType = 'application/octet-stream',
  }) async {
    final results = await _ndk.files.upload(
      file: NdkFile(data: bytes, mimeType: mimeType),
      serverUrls: servers,
    );

    final ok = results
        .where((r) => r.success && r.descriptor != null)
        .toList(growable: false);
    if (ok.isEmpty) {
      final reason = results.map((r) => r.error).whereType<String>().join('; ');
      throw Exception('Blossom upload failed: $reason');
    }

    final url = ok.first.descriptor!.url;
    _log.info('Blossom upload OK (${ok.length}/${results.length}) $url');
    return url;
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
        final response = await http.get(Uri.parse(tryUrl));
        if (response.statusCode == 200 || response.statusCode == 206) {
          final bytes = response.bodyBytes;
          if (bytes.length > maxDownloadBytes) {
            throw Exception(
              'Blossom blob exceeds ${maxDownloadBytes ~/ (1024 * 1024)}MB limit',
            );
          }
          final hash = sha256.convert(bytes).toString();
          if (hash == expectedSha256) {
            return bytes;
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

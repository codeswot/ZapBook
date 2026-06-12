import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:ndk/ndk.dart';
import 'package:ndk/domain_layer/entities/ndk_file.dart';

@lazySingleton
class BlossomService {
  BlossomService(this._ndk);

  final Ndk _ndk;
  final _log = logging.Logger('BlossomService');

  static const List<String> servers = [
    'https://blossom.primal.net',
    'https://cdn.nostr.build',
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
    final response = await _ndk.files.download(url: url, serverUrls: servers);
    if (response.data.length > maxDownloadBytes) {
      throw Exception(
        'Blossom blob exceeds ${maxDownloadBytes ~/ (1024 * 1024)}MB limit',
      );
    }
    return response.data;
  }
}

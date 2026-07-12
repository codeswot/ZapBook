import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:zapbook/core/models/lnurl_models.dart';
import 'package:zapbook/core/utils/bolt11_utils.dart';

class _CacheEntry {
  final LnurlPayResponse response;
  final DateTime expiresAt;

  _CacheEntry(this.response, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

@lazySingleton
class LnurlService {
  LnurlService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final _payResponseCache = <String, _CacheEntry>{};
  final _activePayResolutions = <String, Future<LnurlPayResponse>>{};

  static const _cacheTtl = Duration(minutes: 10);

  @disposeMethod
  void dispose() {
    _client.close();
  }

  Future<LnurlPayResponse> resolveLightningAddress(String lud16) {
    final cached = _payResponseCache[lud16];
    if (cached != null && !cached.isExpired) {
      return Future.value(cached.response);
    }

    if (_activePayResolutions.containsKey(lud16)) {
      return _activePayResolutions[lud16]!;
    }

    final future = _resolveLightningAddressInternal(lud16).whenComplete(() {
      _activePayResolutions.remove(lud16);
    });
    _activePayResolutions[lud16] = future;
    return future;
  }

  Future<LnurlPayResponse> _resolveLightningAddressInternal(
    String lud16,
  ) async {
    final parts = lud16.split('@');
    if (parts.length != 2) {
      throw const LnurlException('Invalid lightning address');
    }

    final user = parts[0];
    final domain = parts[1];
    if (_isForbiddenHost(domain)) {
      throw const LnurlException('Lightning address domain not allowed');
    }

    final url = Uri.https(domain, '/.well-known/lnurlp/$user');
    final response = await _fetchPayResponse(url);

    if (_payResponseCache.length >= 100) {
      _payResponseCache.removeWhere((_, entry) => entry.isExpired);
      if (_payResponseCache.length >= 100) {
        final oldestKeys = _payResponseCache.keys.take(10).toList();
        for (final key in oldestKeys) {
          _payResponseCache.remove(key);
        }
      }
    }
    _payResponseCache[lud16] = _CacheEntry(
      response,
      DateTime.now().add(_cacheTtl),
    );

    return response;
  }

  Future<LnurlPayResponse> _fetchPayResponse(Uri lnurlpUrl) async {
    try {
      final response = await _client
          .get(lnurlpUrl)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw LnurlException('LNURL server returned ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = json['tag'] as String?;
      if (tag != 'payRequest') {
        throw LnurlException('Unsupported LNURL tag: $tag');
      }

      final callback = json['callback'] as String?;
      if (callback == null) {
        throw const LnurlException('Missing callback URL');
      }

      return LnurlPayResponse(
        callback: _validatedCallback(callback),
        minSendable: (json['minSendable'] as num?)?.toInt() ?? 1000,
        maxSendable: (json['maxSendable'] as num?)?.toInt() ?? 100000000,
        commentAllowed: json['commentAllowed'] as int?,
        metadata: json['metadata'] as String?,
      );
    } on SocketException catch (e) {
      throw LnurlException('Network error while resolving LNURL: ${e.message}');
    } on TimeoutException {
      throw const LnurlException('Timeout while resolving LNURL');
    } on FormatException {
      throw const LnurlException('Invalid JSON response from LNURL server');
    }
  }

  Future<LnurlInvoice> fetchInvoice({
    required LnurlPayResponse payResponse,
    required int amountMillisats,
    String? comment,
    String? nostr,
  }) async {
    final url = payResponse.callback.replace(
      queryParameters: {
        ...payResponse.callback.queryParameters,
        'amount': amountMillisats.toString(),
        'comment': ?comment,
        'nostr': ?nostr,
      },
    );

    try {
      final response = await _client
          .get(url)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw LnurlException('Invoice request returned ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final pr = json['pr'] as String?;
      if (pr == null) {
        throw LnurlException(
          'No invoice in response: ${json['reason'] ?? response.body}',
        );
      }

      final invoiceMillisats = Bolt11Utils.amountMillisats(pr);
      if (invoiceMillisats != amountMillisats) {
        throw LnurlException(
          'Invoice amount mismatch: requested $amountMillisats msat, '
          'invoice is for ${invoiceMillisats ?? 'an unspecified amount of'} msat',
        );
      }

      return LnurlInvoice(
        pr: pr,
        successAction: json['successAction'] as Map<String, dynamic>?,
        routes: json['routes'] as List?,
      );
    } on SocketException catch (e) {
      throw LnurlException(
        'Network error while fetching invoice: ${e.message}',
      );
    } on TimeoutException {
      throw const LnurlException('Timeout while fetching invoice');
    } on FormatException {
      throw const LnurlException('Invalid JSON response from LNURL server');
    }
  }

  Uri _validatedCallback(String callback) {
    final uri = Uri.tryParse(callback);
    if (uri == null || uri.scheme != 'https') {
      throw const LnurlException('Callback must use https');
    }
    if (uri.host.isEmpty || _isForbiddenHost(uri.host)) {
      throw const LnurlException('Callback host not allowed');
    }
    return uri;
  }

  bool _isForbiddenHost(String host) {
    final lower = host.toLowerCase();
    if (lower == 'localhost' ||
        lower.endsWith('.local') ||
        lower.endsWith('.internal') ||
        lower.endsWith('.onion')) {
      return true;
    }
    final ip = InternetAddress.tryParse(lower);
    if (ip == null) return false;
    if (ip.isLoopback || ip.isLinkLocal || ip.isMulticast) return true;
    final raw = ip.rawAddress;
    if (ip.type == InternetAddressType.IPv4) {
      return raw[0] == 0 ||
          raw[0] == 10 ||
          (raw[0] == 100 && raw[1] >= 64 && raw[1] <= 127) ||
          (raw[0] == 172 && raw[1] >= 16 && raw[1] <= 31) ||
          (raw[0] == 192 && raw[1] == 168) ||
          (raw[0] == 169 && raw[1] == 254);
    }
    return raw[0] == 0xfc || raw[0] == 0xfd;
  }
}

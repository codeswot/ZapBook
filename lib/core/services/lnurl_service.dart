import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

@lazySingleton
class LnurlService {
  const LnurlService();

  Future<LnurlPayResponse> resolveLightningAddress(String lud16) async {
    final parts = lud16.split('@');
    if (parts.length != 2) throw LnurlException('Invalid lightning address');

    final user = parts[0];
    final domain = parts[1];
    if (_isForbiddenHost(domain)) {
      throw LnurlException('Lightning address domain not allowed');
    }
    final url = Uri.https(domain, '/.well-known/lnurlp/$user');
    return _fetchPayResponse(url);
  }

  Future<LnurlPayResponse> _fetchPayResponse(Uri lnurlpUrl) async {
    final response = await http
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
    if (callback == null) throw LnurlException('Missing callback URL');

    return LnurlPayResponse(
      callback: _validatedCallback(callback),
      minSendable: (json['minSendable'] as num?)?.toInt() ?? 1000,
      maxSendable: (json['maxSendable'] as num?)?.toInt() ?? 100000000,
      commentAllowed: json['commentAllowed'] as int?,
      metadata: json['metadata'] as String?,
    );
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

    final response = await http.get(url).timeout(const Duration(seconds: 15));
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
    final invoiceMillisats = bolt11AmountMillisats(pr);
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
  }

  static final RegExp _bolt11Prefix = RegExp(
    r'^ln(bc|tb|tbs|bcrt|sb)(\d+)?([munp])?1',
  );

  static int? bolt11AmountMillisats(String pr) {
    final match = _bolt11Prefix.firstMatch(pr.toLowerCase());
    if (match == null) throw LnurlException('Invalid BOLT11 invoice');
    final digits = match.group(2);
    if (digits == null) return null;
    final amount = BigInt.parse(digits);
    final msatPerBtc = BigInt.from(100000000000);
    final divisor = switch (match.group(3)) {
      null => BigInt.one,
      'm' => BigInt.from(1000),
      'u' => BigInt.from(1000000),
      'n' => BigInt.from(1000000000),
      'p' => BigInt.from(1000000000000),
      _ => throw LnurlException('Invalid BOLT11 multiplier'),
    };
    final msats = amount * msatPerBtc ~/ divisor;
    return msats.isValidInt ? msats.toInt() : null;
  }

  Uri _validatedCallback(String callback) {
    final uri = Uri.tryParse(callback);
    if (uri == null || uri.scheme != 'https') {
      throw LnurlException('Callback must use https');
    }
    if (uri.host.isEmpty || _isForbiddenHost(uri.host)) {
      throw LnurlException('Callback host not allowed');
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

class LnurlPayResponse {
  final Uri callback;
  final int minSendable;
  final int maxSendable;
  final int? commentAllowed;
  final String? metadata;

  const LnurlPayResponse({
    required this.callback,
    required this.minSendable,
    required this.maxSendable,
    this.commentAllowed,
    this.metadata,
  });
}

class LnurlInvoice {
  final String pr;
  final Map<String, dynamic>? successAction;
  final List? routes;

  const LnurlInvoice({required this.pr, this.successAction, this.routes});
}

class LnurlException implements Exception {
  final String message;
  const LnurlException(this.message);

  @override
  String toString() => 'LnurlException: $message';
}

import 'dart:convert';

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
      callback: Uri.parse(callback),
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
  }) async {
    final url = payResponse.callback.replace(
      queryParameters: {
        ...payResponse.callback.queryParameters,
        'amount': amountMillisats.toString(),
        'comment': ?comment,
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
    return LnurlInvoice(
      pr: pr,
      successAction: json['successAction'] as Map<String, dynamic>?,
      routes: json['routes'] as List?,
    );
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

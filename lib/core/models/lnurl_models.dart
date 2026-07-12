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

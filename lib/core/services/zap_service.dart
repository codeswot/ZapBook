import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/services/lnurl_service.dart';

@lazySingleton
class ZapService {
  ZapService(this._lnurl, this._ndk);

  final LnurlService _lnurl;
  final Ndk _ndk;

  Future<ZapResult> send({
    required String recipientLud16,
    required String recipientPubkey,
    required String targetEventId,
    required ZapGesture gesture,
    int? customSats,
  }) async {
    final amountSats = gesture.sats ?? customSats ?? 21;
    if (amountSats <= 0) throw ZapException('Amount must be positive');

    final amountMillisats = amountSats * 1000;

    final payResponse = await _lnurl.resolveLightningAddress(recipientLud16);

    if (amountMillisats < payResponse.minSendable) {
      throw ZapException('Amount below minimum');
    }
    if (amountMillisats > payResponse.maxSendable) {
      throw ZapException('Amount above maximum');
    }

    final invoice = await _lnurl.fetchInvoice(
      payResponse: payResponse,
      amountMillisats: amountMillisats,
      comment: gesture.label,
    );

    return ZapResult(
      invoice: invoice.pr,
      amountSats: amountSats,
      gesture: gesture,
      recipientPubkey: recipientPubkey,
      targetEventId: targetEventId,
    );
  }

  Future<bool> payWithFallback(String invoice) async {
    final uri = Uri.tryParse('lightning:$invoice');
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void subscribeToReceipts({
    required String targetEventId,
    required void Function(Nip01Event event) onReceipt,
  }) {
    final sub = _ndk.requests.subscription(
      filter: Filter(
        kinds: const [9735],
        tags: {
          '#e': [targetEventId],
        },
      ),
    );
    sub.stream.listen(onReceipt);
  }
}

class ZapResult {
  final String invoice;
  final int amountSats;
  final ZapGesture gesture;
  final String recipientPubkey;
  final String targetEventId;

  const ZapResult({
    required this.invoice,
    required this.amountSats,
    required this.gesture,
    required this.recipientPubkey,
    required this.targetEventId,
  });
}

class ZapException implements Exception {
  final String message;
  const ZapException(this.message);
  @override
  String toString() => 'ZapException: $message';
}

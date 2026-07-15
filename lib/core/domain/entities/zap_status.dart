import 'package:zapbook/core/domain/zap_gesture.dart';

enum ZapStatus { paidNwc, pendingExternal, failed }

class ZapException implements Exception {
  final String message;
  const ZapException(this.message);
  @override
  String toString() => 'ZapException: $message';
}

class ZapResult {
  final String invoice;
  final String zapRequestId;
  final int amountSats;
  final ZapGesture gesture;
  final String recipientPubkey;
  final String targetActivitytId;
  final String? supportInvoice;
  final int supportAmount;

  bool get hasSupportZap => supportInvoice != null && supportAmount > 0;

  const ZapResult({
    required this.invoice,
    required this.zapRequestId,
    required this.amountSats,
    required this.gesture,
    required this.recipientPubkey,
    required this.targetActivitytId,
    this.supportInvoice,
    this.supportAmount = 0,
  });
}

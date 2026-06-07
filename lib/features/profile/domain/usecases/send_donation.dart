import 'package:injectable/injectable.dart';

import 'package:zapbook/core/services/lnurl_service.dart';

@injectable
final class SendDonation {
  const SendDonation(this._lnurl);

  final LnurlService _lnurl;

  static const recipient = 'zapbook@blink.sv';

  Future<DonationInvoice> call({
    required int amountSats,
    String? comment,
  }) async {
    if (amountSats <= 0) throw DonationException('Amount must be positive');

    final payResponse = await _lnurl.resolveLightningAddress(recipient);

    final amountMillisats = amountSats * 1000;
    if (amountMillisats < payResponse.minSendable) {
      throw DonationException(
        'Minimum ${(payResponse.minSendable / 1000).round()} sats required',
      );
    }
    if (amountMillisats > payResponse.maxSendable) {
      throw DonationException(
        'Maximum ${(payResponse.maxSendable / 1000).round()} sats allowed',
      );
    }

    final invoice = await _lnurl.fetchInvoice(
      payResponse: payResponse,
      amountMillisats: amountMillisats,
      comment: (comment != null && comment.isNotEmpty) ? comment : null,
    );

    return DonationInvoice(pr: invoice.pr, amountSats: amountSats);
  }
}

class DonationInvoice {
  final String pr;
  final int amountSats;

  const DonationInvoice({required this.pr, required this.amountSats});
}

class DonationException implements Exception {
  final String message;
  const DonationException(this.message);
  @override
  String toString() => 'DonationException: $message';
}

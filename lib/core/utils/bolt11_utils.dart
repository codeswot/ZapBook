import 'package:zapbook/core/models/lnurl_models.dart';

class Bolt11Utils {
  static final RegExp _bolt11Prefix = RegExp(
    r'^ln(bc|tb|tbs|bcrt|sb)(\d+)?([munp])?1',
  );

  static int? amountMillisats(String pr) {
    final match = _bolt11Prefix.firstMatch(pr.toLowerCase());
    if (match == null) throw const LnurlException('Invalid BOLT11 invoice');
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
      _ => throw const LnurlException('Invalid BOLT11 multiplier'),
    };
    final msats = amount * msatPerBtc ~/ divisor;
    return msats.isValidInt ? msats.toInt() : null;
  }
}

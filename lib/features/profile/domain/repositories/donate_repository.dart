import 'package:zapbook/core/services/zap_service.dart';

abstract class DonateRepository {
  Future<ZapResult> donate({required int amountSats, String? comment});
  Future<ZapStatus> payWithFallback(String invoice);
  Future<void> copyToClipboard(String text);
}

import 'package:zapbook/core/domain/entities/zap_status.dart';

abstract class DonateRepository {
  Future<ZapResult> donate({required int amountSats, String? comment});
  Future<ZapStatus> payWithFallback(String invoice);
  Future<void> copyToClipboard(String text);
}

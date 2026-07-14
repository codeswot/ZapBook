import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/services/zap_service.dart';
import 'package:zapbook/core/data/infrastructure/clipboard_service.dart';

@injectable
class DonateUseCases {
  final ZapService _zap;
  final ClipboardService _clipboard;

  DonateUseCases(this._zap, this._clipboard);

  Future<ZapResult> donate({required int amountSats, String? comment}) => 
    _zap.donate(amountSats: amountSats, comment: comment);

  Future<ZapStatus> payWithFallback(String invoice) => 
    _zap.payWithFallback(invoice);

  Future<void> copyToClipboard(String text) => 
    _clipboard.copy(text);
}

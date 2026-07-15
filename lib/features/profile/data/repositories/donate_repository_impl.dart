import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/entities/zap_status.dart';
import 'package:zapbook/core/data/infrastructure/zap_service.dart';
import 'package:zapbook/core/data/infrastructure/clipboard_service.dart';
import 'package:zapbook/features/profile/domain/repositories/donate_repository.dart';

@Injectable(as: DonateRepository)
class DonateRepositoryImpl implements DonateRepository {
  final ZapService _zap;
  final ClipboardService _clipboard;

  DonateRepositoryImpl(this._zap, this._clipboard);

  @override
  Future<ZapResult> donate({required int amountSats, String? comment}) =>
      _zap.donate(amountSats: amountSats, comment: comment);

  @override
  Future<ZapStatus> payWithFallback(String invoice) =>
      _zap.payWithFallback(invoice);

  @override
  Future<void> copyToClipboard(String text) => _clipboard.copy(text);
}

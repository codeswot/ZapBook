import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/entities/zap_status.dart';
import 'package:zapbook/features/profile/domain/repositories/donate_repository.dart';

@injectable
class DonateUseCases {
  final DonateRepository _repository;

  DonateUseCases(this._repository);

  Future<ZapResult> donate({required int amountSats, String? comment}) =>
      _repository.donate(amountSats: amountSats, comment: comment);

  Future<ZapStatus> payWithFallback(String invoice) =>
      _repository.payWithFallback(invoice);

  Future<void> copyToClipboard(String text) =>
      _repository.copyToClipboard(text);
}

import 'package:injectable/injectable.dart';
import 'package:zapbook/features/cheers/domain/repositories/cheers_repository.dart';

@injectable
class SendCheersZap {
  const SendCheersZap(this._repository);

  final CheersRepository _repository;

  Future<void> call({
    required String activityId,
    required int amount,
    required String reactionType,
  }) => _repository.sendZap(activityId, amount, reactionType);
}

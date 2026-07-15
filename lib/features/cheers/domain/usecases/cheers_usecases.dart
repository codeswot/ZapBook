import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/services/zap_service.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';
import 'package:zapbook/features/cheers/domain/repositories/cheers_repository.dart';

@injectable
class WatchCheersActivitiesUseCase {
  const WatchCheersActivitiesUseCase(this._repository);

  final CheersRepository _repository;

  Stream<List<CheersActivity>> call() => _repository.watchActivities();
}

@injectable
class SendCheersZapUseCase {
  const SendCheersZapUseCase(this._repository);

  final CheersRepository _repository;

  Future<ZapStatus> call({
    required CheersActivity activity,
    required ZapGesture gesture,
    required int amount,
    String? comment,
  }) => _repository.sendZap(
    activity: activity,
    gesture: gesture,
    amount: amount,
    comment: comment,
  );
}

@injectable
class SendCheersNudgeUseCase {
  const SendCheersNudgeUseCase(this._repository);

  final CheersRepository _repository;

  Future<String?> getMyPubkey() => _repository.getMyPubkey();

  Future<void> sendNudge({required String groupId, required String toNpub}) =>
      _repository.sendNudge(groupId: groupId, toNpub: toNpub);

  Future<void> sendNudgeReady({
    required String groupId,
    required String nudgeId,
    required String toNpub,
  }) => _repository.sendNudgeReady(
    groupId: groupId,
    nudgeId: nudgeId,
    toNpub: toNpub,
  );
}

@injectable
class LookupLud16UseCase {
  const LookupLud16UseCase(this._repository);

  final CheersRepository _repository;

  Future<String?> call(String pubkey) => _repository.lookupLud16(pubkey);
}

@injectable
class CopyCheersActivityTextUseCase {
  const CopyCheersActivityTextUseCase(this._repository);

  final CheersRepository _repository;

  Future<void> call(String text) => _repository.copyText(text);
}

import 'package:injectable/injectable.dart';
import 'package:zapbook/features/cheers/data/datasources/cheers_data_source.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/domain/entities/zap_status.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';
import 'package:zapbook/features/cheers/domain/repositories/cheers_repository.dart';

@LazySingleton(as: CheersRepository)
class CheersRepositoryImpl implements CheersRepository {
  const CheersRepositoryImpl(this._dataSource);

  final CheersDataSource _dataSource;

  @override
  Stream<List<CheersActivity>> watchActivities() =>
      _dataSource.watchActivities();

  @override
  Future<ZapStatus> sendZap({
    required CheersActivity activity,
    required ZapGesture gesture,
    required int amount,
    String? comment,
  }) => _dataSource.sendZap(
    activity: activity,
    gesture: gesture,
    amount: amount,
    comment: comment,
  );

  @override
  Future<void> sendNudge({required String groupId, required String toNpub}) =>
      _dataSource.sendNudge(groupId: groupId, toNpub: toNpub);

  @override
  Future<void> sendNudgeReady({
    required String groupId,
    required String nudgeId,
    required String toNpub,
  }) => _dataSource.sendNudgeReady(
    groupId: groupId,
    nudgeId: nudgeId,
    toNpub: toNpub,
  );

  @override
  Future<String?> lookupLud16(String pubkey) => _dataSource.lookupLud16(pubkey);

  @override
  Future<String?> getMyPubkey() => _dataSource.getMyPubkey();

  @override
  Future<void> copyText(String text) => _dataSource.copyText(text);

  @override
  Future<void> shareText(String text) => _dataSource.shareText(text);

  @override
  Future<void> postNote(String text, {List<String> mentionNpubs = const []}) =>
      _dataSource.postNote(text, mentionNpubs: mentionNpubs);
}

import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/domain/entities/zap_status.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';

abstract interface class CheersRepository {
  Stream<List<CheersActivity>> watchActivities();

  Future<void> markAsRead(String activityId);

  Future<ZapStatus> sendZap({
    required CheersActivity activity,
    required ZapGesture gesture,
    required int amount,
    String? comment,
  });

  Future<void> sendNudge({required String groupId, required String toNpub});

  Future<void> sendNudgeReady({
    required String groupId,
    required String nudgeId,
    required String toNpub,
  });

  Future<String?> lookupLud16(String pubkey);

  Future<String?> getMyPubkey();

  Future<void> copyText(String text);

  Future<void> shareText(String text);

  Future<void> postNote(String text, {List<String> mentionNpubs});
}

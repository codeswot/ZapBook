import 'package:zapbook/core/domain/entities/cheers_activity_type.dart';
import 'package:equatable/equatable.dart';
import 'package:zapbook/core/domain/entities/app_message.dart';
import 'package:zapbook/core/models/circle_member_progress.dart';

final class CheersActivityMessage extends Equatable {
  const CheersActivityMessage({
    required this.id,
    required this.actorNpub,
    this.circleBookId,
    this.groupId,
    required this.activityDescription,
    required this.timestamp,
    required this.type,
    required this.isUnread,
    this.nudgeId,
    this.thumbsUpCount = 0,
    this.clapCount = 0,
    this.fireCount = 0,
    this.rocketCount = 0,
    this.trophyCount = 0,
    this.zapAmount,
    this.zapReaction,
    this.zapTargetId,
    this.zapTargetDescription,
    this.zapRecipientNpub,
    this.bookTitle,
  });

  static CheersActivityMessage? cheerFromProgress({
    required String id,
    required String actorNpub,
    required String groupId,
    required int timestampSecs,
    CircleMemberProgress? previous,
    required CircleMemberProgress next,
    String? bookTitle,
  }) {
    final timestamp = DateTime.fromMillisecondsSinceEpoch(timestampSecs * 1000);
    final prevCompleted = previous?.completed ?? false;
    final prevMilestones = previous?.milestonesReached ?? 0;

    if (next.completed && !prevCompleted) {
      return CheersActivityMessage(
        id: id,
        actorNpub: actorNpub,
        circleBookId: next.bookId,
        groupId: groupId,
        activityDescription: 'Finished the book',
        timestamp: timestamp,
        type: CheersActivityType.milestone,
        isUnread: true,
        bookTitle: bookTitle,
      );
    }

    if (next.milestonesReached > prevMilestones) {
      final pct = next.progressPercentage * 100;
      final pctStr = pct > 0 ? ' (${pct.toStringAsFixed(1)}%)' : '';
      return CheersActivityMessage(
        id: id,
        actorNpub: actorNpub,
        circleBookId: next.bookId,
        groupId: groupId,
        activityDescription:
            'Milestone ${next.milestonesReached}: page ${next.pageIndex}$pctStr',
        timestamp: timestamp,
        type: CheersActivityType.milestone,
        isUnread: true,
        bookTitle: bookTitle,
        zapTargetId: next.id,
      );
    }

    return null;
  }

  static CheersActivityMessage? fromAppMessage(
    AppMessage msg, {
    String? bookTitle,
  }) {
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      msg.timestampSecs * 1000,
    );

    if (msg is CheersMessage) {
      return CheersActivityMessage(
        id: msg.id,
        actorNpub: msg.senderNpub,
        circleBookId: msg.payload['circleBookId'] as String?,
        groupId: msg.groupId,
        activityDescription:
            msg.payload['message'] as String? ?? 'Sent a cheer',
        timestamp: timestamp,
        type: CheersActivityType.cheer,
        isUnread: true,
        clapCount: msg.payload['clapCount'] as int? ?? 0,
        fireCount: msg.payload['fireCount'] as int? ?? 0,
        rocketCount: msg.payload['rocketCount'] as int? ?? 0,
        thumbsUpCount: msg.payload['thumbsUpCount'] as int? ?? 0,
        trophyCount: msg.payload['trophyCount'] as int? ?? 0,
        bookTitle: bookTitle,
      );
    }

    if (msg is ZapSentMessage) {
      return CheersActivityMessage(
        id: msg.id,
        actorNpub: msg.senderNpub,
        circleBookId: msg.payload['circleBookId'] as String?,
        groupId: msg.groupId,
        activityDescription:
            msg.payload['description'] as String? ?? 'Sent a zap',
        timestamp: timestamp,
        type: CheersActivityType.zap,
        isUnread: true,
        zapAmount: msg.payload['amount'] as int?,
        zapReaction: msg.payload['reaction'] as String?,
        zapTargetId: msg.payload['targetId'] as String?,
        zapTargetDescription: msg.payload['targetDescription'] as String?,
        zapRecipientNpub: msg.payload['recipientNpub'] as String?,
        bookTitle: bookTitle,
      );
    }

    if (msg is ZapNudgeMessage) {
      final nudgeId = msg.payload['nudgeId'] as String? ?? '';
      return CheersActivityMessage(
        id: msg.id,
        actorNpub: msg.senderNpub,
        circleBookId: msg.payload['circleBookId'] as String?,
        groupId: msg.groupId,
        activityDescription:
            'wants to zap you, but your receiving address isn\'t set. Set it in your profile, then tap to buzz them.',
        timestamp: timestamp,
        type: CheersActivityType.zapNudge,
        isUnread: true,
        nudgeId: nudgeId,
        bookTitle: bookTitle,
      );
    }

    if (msg is ZapReadyMessage) {
      final nudgeId = msg.payload['nudgeId'] as String? ?? '';
      return CheersActivityMessage(
        id: msg.id,
        actorNpub: msg.senderNpub,
        circleBookId: msg.payload['circleBookId'] as String?,
        groupId: msg.groupId,
        activityDescription: 'set up their wallet — zap them!',
        timestamp: timestamp,
        type: CheersActivityType.zapReady,
        isUnread: true,
        nudgeId: nudgeId,
        bookTitle: bookTitle,
      );
    }

    if (msg is ReseedRequestMessage) {
      return CheersActivityMessage(
        id: msg.id,
        actorNpub: msg.senderNpub,
        circleBookId: msg.payload['circleDirId'] as String?,
        groupId: msg.groupId,
        activityDescription: 'Requested a re-seed for missing segments',
        timestamp: timestamp,
        type: CheersActivityType.adminAction,
        isUnread: true,
        bookTitle: bookTitle,
      );
    }

    return null;
  }

  final String id;
  final String actorNpub;
  final String? circleBookId;
  final String? groupId;
  final String activityDescription;
  final DateTime timestamp;
  final CheersActivityType type;
  final bool isUnread;
  final String? nudgeId;
  final int thumbsUpCount;
  final int clapCount;
  final int fireCount;
  final int rocketCount;
  final int trophyCount;
  final int? zapAmount;
  final String? zapReaction;
  final String? zapTargetId;
  final String? zapTargetDescription;
  final String? zapRecipientNpub;
  final String? bookTitle;

  @override
  List<Object?> get props => [
    id,
    actorNpub,
    circleBookId,
    groupId,
    activityDescription,
    timestamp,
    type,
    isUnread,
    nudgeId,
    thumbsUpCount,
    clapCount,
    fireCount,
    rocketCount,
    trophyCount,
    zapAmount,
    zapReaction,
    zapTargetId,
    zapTargetDescription,
    zapRecipientNpub,
    bookTitle,
  ];
}

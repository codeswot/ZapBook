import 'package:equatable/equatable.dart';
import 'package:zapbook/core/models/app_message.dart';

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
        type: 'cheer',
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
        type: 'zap',
        isUnread: true,
        zapAmount: msg.payload['amount'] as int?,
        zapReaction: msg.payload['reaction'] as String?,
        zapTargetId: msg.payload['targetId'] as String?,
        zapTargetDescription: msg.payload['targetDescription'] as String?,
        zapRecipientNpub: msg.payload['recipientNpub'] as String?,
        bookTitle: bookTitle,
      );
    }

    if (msg is MilestoneMessage) {
      final milestoneIdx = msg.payload['milestone_idx'] as int? ?? 0;
      final currentPage = msg.payload['current_page'] as int? ?? 0;
      final progressPct =
          (msg.payload['progress_pct'] as num?)?.toDouble() ?? 0.0;
      final pctStr = progressPct > 0
          ? ' (${progressPct.toStringAsFixed(1)}%)'
          : '';
      return CheersActivityMessage(
        id: msg.id,
        actorNpub: msg.senderNpub,
        circleBookId: msg.payload['book_id'] as String?,
        groupId: msg.groupId,
        activityDescription:
            'Milestone ${milestoneIdx + 1}: page $currentPage$pctStr',
        timestamp: timestamp,
        type: 'milestone',
        isUnread: true,
        bookTitle: bookTitle,
      );
    }

    if (msg is BookCompletedMessage) {
      return CheersActivityMessage(
        id: msg.id,
        actorNpub: msg.senderNpub,
        circleBookId: msg.payload['book_id'] as String?,
        groupId: msg.groupId,
        activityDescription: 'Finished the book',
        timestamp: timestamp,
        type: 'milestone',
        isUnread: true,
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
        type: 'zap_nudge',
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
        type: 'zap_ready',
        isUnread: true,
        nudgeId: nudgeId,
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
  final String type;
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

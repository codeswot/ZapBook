import 'package:zapbook/core/domain/entities/cheers_activity_type.dart';

class CheersActivity {
  final String id;
  final String groupId;
  final String actorNpub;
  final String otherPartyNpub;
  final String otherPartyName;
  final String otherPartyPicture;
  final String actorName;
  final String actorPicture;
  final String? bookId;
  final String targetId;
  final String targetDescription;
  final DateTime timestamp;
  final String? bookCircleTitle;
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
  final bool isMine;
  final int? pageCount;

  CheersActivity({
    required this.id,
    required this.groupId,
    required this.actorNpub,
    required this.otherPartyNpub,
    required this.targetId,
    required this.targetDescription,
    required this.timestamp,
    required this.type,
    required this.isUnread,
    required this.isMine,
    this.nudgeId,
    this.thumbsUpCount = 0,
    this.clapCount = 0,
    this.fireCount = 0,
    this.rocketCount = 0,
    this.trophyCount = 0,
    this.zapAmount,
    this.zapReaction,
    this.bookCircleTitle,
    required this.otherPartyName,
    required this.otherPartyPicture,
    required this.actorName,
    required this.actorPicture,
    this.bookId,
    this.pageCount,
  });
}

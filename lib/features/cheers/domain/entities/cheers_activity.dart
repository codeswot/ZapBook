class CheersActivity {
  final String id;
  final String groupId;
  final String senderNpub;
  final String recipientNpub;
  final String recipientDisplayName;
  final String recipientProfilePictureUrl;
  final String senderDisplayName;
  final String senderProfilePictureUrl;
  final String? bookId;
  final String targetId;
  final String targetDescription;
  final DateTime timestamp;
  final String? bookCircleTitle;
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
  final bool isMine;

  CheersActivity({
    required this.id,
    required this.groupId,
    required this.senderNpub,
    required this.recipientNpub,
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
    required this.recipientDisplayName,
    required this.recipientProfilePictureUrl,
    required this.senderDisplayName,
    required this.senderProfilePictureUrl,
    this.bookId,
  });
}

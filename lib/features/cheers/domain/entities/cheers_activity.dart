import 'package:equatable/equatable.dart';

final class CheersActivity extends Equatable {
  const CheersActivity({
    required this.id,
    required this.actorNpub,
    required this.actorName,
    this.actorAvatar,
    required this.bookTitle,
    this.bookId,
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
  });

  final String id;
  final String actorNpub;
  final String actorName;
  final String? actorAvatar;
  final String bookTitle;
  final String? bookId;
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

  CheersActivity copyWith({String? actorName, String? actorAvatar}) =>
      CheersActivity(
        id: id,
        actorNpub: actorNpub,
        actorName: actorName ?? this.actorName,
        actorAvatar: actorAvatar ?? this.actorAvatar,
        bookTitle: bookTitle,
        bookId: bookId,
        activityDescription: activityDescription,
        timestamp: timestamp,
        type: type,
        isUnread: isUnread,
        nudgeId: nudgeId,
        thumbsUpCount: thumbsUpCount,
        clapCount: clapCount,
        fireCount: fireCount,
        rocketCount: rocketCount,
        trophyCount: trophyCount,
        zapAmount: zapAmount,
        zapReaction: zapReaction,
        zapTargetId: zapTargetId,
        zapTargetDescription: zapTargetDescription,
        zapRecipientNpub: zapRecipientNpub,
      );

  @override
  List<Object?> get props => [
    id,
    actorNpub,
    actorName,
    actorAvatar,
    bookTitle,
    bookId,
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
  ];
}

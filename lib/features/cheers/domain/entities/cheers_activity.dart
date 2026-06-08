import 'package:equatable/equatable.dart';

final class CheersActivity extends Equatable {
  const CheersActivity({
    required this.id,
    required this.actorNpub,
    required this.actorName,
    this.actorAvatar,
    required this.bookTitle,
    required this.activityDescription,
    required this.timestamp,
    required this.type,
    required this.isUnread,
    this.thumbsUpCount = 0,
    this.clapCount = 0,
    this.fireCount = 0,
    this.rocketCount = 0,
    this.trophyCount = 0,
  });

  final String id;
  final String actorNpub;
  final String actorName;
  final String? actorAvatar;
  final String bookTitle;
  final String activityDescription;
  final DateTime timestamp;
  final String type;
  final bool isUnread;
  final int thumbsUpCount;
  final int clapCount;
  final int fireCount;
  final int rocketCount;
  final int trophyCount;

  @override
  List<Object?> get props => [
        id,
        actorNpub,
        actorName,
        actorAvatar,
        bookTitle,
        activityDescription,
        timestamp,
        type,
        isUnread,
        thumbsUpCount,
        clapCount,
        fireCount,
        rocketCount,
        trophyCount,
      ];
}

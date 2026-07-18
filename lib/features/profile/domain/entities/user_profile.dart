import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String npub;
  final String displayName;
  final String picture;
  final String lightningAddress;
  final int satsEarned;
  final int dayStreak;
  final int booksRead;
  final int milestones;
  final bool isFollow;
  final bool isSelf;

  const UserProfile({
    required this.npub,
    required this.displayName,
    required this.picture,
    required this.lightningAddress,
    required this.satsEarned,
    required this.dayStreak,
    required this.booksRead,
    required this.milestones,
    this.isFollow = false,
    this.isSelf = false,
  });

  bool get hasLightning => lightningAddress.isNotEmpty;

  UserProfile copyWith({bool? isFollow}) => UserProfile(
    npub: npub,
    displayName: displayName,
    picture: picture,
    lightningAddress: lightningAddress,
    satsEarned: satsEarned,
    dayStreak: dayStreak,
    booksRead: booksRead,
    milestones: milestones,
    isFollow: isFollow ?? this.isFollow,
    isSelf: isSelf,
  );

  @override
  List<Object?> get props => [
    npub,
    displayName,
    picture,
    lightningAddress,
    satsEarned,
    dayStreak,
    booksRead,
    milestones,
    isFollow,
    isSelf,
  ];
}

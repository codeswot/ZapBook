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
  final int joinedYear;

  const UserProfile({
    required this.npub,
    required this.displayName,
    required this.picture,
    required this.lightningAddress,
    required this.satsEarned,
    required this.dayStreak,
    required this.booksRead,
    required this.milestones,
    required this.joinedYear,
  });

  bool get hasLightning => lightningAddress.isNotEmpty;

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
    joinedYear,
  ];
}

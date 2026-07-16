import 'package:equatable/equatable.dart';

import 'package:zapbook/features/profile/domain/entities/user_profile.dart';

sealed class UserProfileState extends Equatable {
  const UserProfileState();

  @override
  List<Object?> get props => [];
}

final class UserProfileLoading extends UserProfileState {
  const UserProfileLoading();
}

final class UserProfileLoaded extends UserProfileState {
  final UserProfile profile;

  const UserProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

final class UserProfileError extends UserProfileState {
  final String message;

  const UserProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

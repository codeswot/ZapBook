import 'package:equatable/equatable.dart';

import 'package:zapbook/features/profile/domain/entities/user_profile.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

final class ProfileLoaded extends ProfileState {
  final UserProfile profile;
  final String? nwcWalletName;

  const ProfileLoaded(this.profile, {this.nwcWalletName});

  bool get nwcConnected => nwcWalletName != null;

  @override
  List<Object?> get props => [profile, nwcWalletName];
}

final class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

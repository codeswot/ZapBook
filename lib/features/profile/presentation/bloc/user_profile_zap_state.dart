part of 'user_profile_zap_cubit.dart';

sealed class UserProfileZapState extends Equatable {
  const UserProfileZapState();

  @override
  List<Object?> get props => [];
}

class UserProfileZapInitial extends UserProfileZapState {
  const UserProfileZapInitial();
}

class UserProfileZapLoading extends UserProfileZapState {
  final ZapGesture gesture;
  const UserProfileZapLoading(this.gesture);

  @override
  List<Object?> get props => [gesture];
}

class UserProfileZapSuccess extends UserProfileZapState {
  final int amountSats;
  final String profileLabel;
  const UserProfileZapSuccess({
    required this.amountSats,
    required this.profileLabel,
  });

  @override
  List<Object?> get props => [amountSats, profileLabel];
}

class UserProfileZapFailure extends UserProfileZapState {
  final String message;
  const UserProfileZapFailure(this.message);

  @override
  List<Object?> get props => [message];
}

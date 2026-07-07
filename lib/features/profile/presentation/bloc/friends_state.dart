import 'package:equatable/equatable.dart';
import 'package:zapbook/core/domain/contact.dart';

sealed class FriendsState extends Equatable {
  const FriendsState();

  @override
  List<Object?> get props => [];
}

class FriendsLoading extends FriendsState {
  const FriendsLoading();
}

class FriendsLoaded extends FriendsState {
  final List<Contact> friends;
  const FriendsLoaded(this.friends);

  @override
  List<Object?> get props => [friends];
}

class FriendsBusy extends FriendsState {
  final List<Contact> friends;
  final String busyNpub;
  final bool adding;
  const FriendsBusy({
    required this.friends,
    required this.busyNpub,
    this.adding = false,
  });

  @override
  List<Object?> get props => [friends, busyNpub, adding];
}

class FriendsError extends FriendsState {
  final List<Contact> friends;
  final String message;
  const FriendsError({required this.friends, required this.message});

  @override
  List<Object?> get props => [friends, message];

  static FriendsState from(FriendsState state, String message) {
    final friends = state is FriendsLoaded
        ? state.friends
        : state is FriendsBusy
        ? state.friends
        : <Contact>[];
    return FriendsError(friends: friends, message: message);
  }
}

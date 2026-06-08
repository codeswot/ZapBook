import 'package:zapbook/core/domain/contact.dart';

sealed class FriendsState {
  const FriendsState();
}

class FriendsLoading extends FriendsState {
  const FriendsLoading();
}

class FriendsLoaded extends FriendsState {
  final List<Contact> friends;
  const FriendsLoaded(this.friends);
}

class FriendsBusy extends FriendsState {
  final List<Contact> friends;
  final String busyNpub;
  final bool adding;
  const FriendsBusy({required this.friends, required this.busyNpub, this.adding = false});
}

class FriendsError extends FriendsState {
  final List<Contact> friends;
  final String message;
  const FriendsError({required this.friends, required this.message});

  static FriendsState from(FriendsState state, String message) {
    final friends = state is FriendsLoaded
        ? state.friends
        : state is FriendsBusy
            ? state.friends
            : <Contact>[];
    return FriendsError(friends: friends, message: message);
  }
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;

import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/features/profile/presentation/bloc/friends_state.dart';

@injectable
class FriendsCubit extends Cubit<FriendsState> {
  FriendsCubit(this._contacts) : super(const FriendsLoading()) {
    _sub = _contacts.friendsStream.listen((friends) {
      if (!isClosed && state is! FriendsBusy) emit(FriendsLoaded(friends));
    });
  }

  final ContactService _contacts;
  final _log = logging.Logger('FriendsCubit');
  StreamSubscription<List<Contact>>? _sub;

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }

  Future<void> load() async {
    emit(const FriendsLoading());
    try {
      final friends = await _contacts.friends();
      emit(FriendsLoaded(friends));
    } on Object catch (e, stack) {
      _log.warning('Load friends failed', e, stack);
      emit(const FriendsLoaded([]));
    }
  }

  Future<void> addNpub(String npub) async {
    if (npub.isEmpty) return;

    if (!_contacts.isValidNpub(npub)) {
      emit(FriendsError.from(state, 'Not a valid npub'));
      return;
    }

    final current = _currentFriends;
    emit(FriendsBusy(friends: current, busyNpub: npub, adding: true));

    try {
      await _contacts.add(npub);
      final friends = await _contacts.friends();
      emit(FriendsLoaded(friends));
    } on ContactException catch (e) {
      emit(FriendsError.from(state, e.message));
    } on Exception catch (e, stack) {
      _log.warning('Add contact failed', e, stack);
      emit(FriendsError.from(state, 'Could not add contact'));
    }
  }

  Future<void> remove(String npub) async {
    final current = _currentFriends;
    emit(FriendsBusy(friends: current, busyNpub: npub));

    try {
      await _contacts.remove(npub);
      final friends = await _contacts.friends();
      emit(FriendsLoaded(friends));
    } on Object catch (e, stack) {
      _log.warning('Remove contact failed', e, stack);
      emit(FriendsLoaded(current));
    }
  }

  int get contactCount => _contacts.stored.length;

  List<Contact> get _currentFriends {
    final s = state;
    if (s is FriendsLoaded) return s.friends;
    if (s is FriendsBusy) return s.friends;
    if (s is FriendsError) return s.friends;
    return const [];
  }
}

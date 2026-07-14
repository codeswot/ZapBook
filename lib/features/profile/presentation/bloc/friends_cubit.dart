import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;

import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/features/profile/domain/usecases/friends_usecases.dart';
import 'package:zapbook/features/profile/presentation/bloc/friends_state.dart';

@lazySingleton
class FriendsCubit extends Cubit<FriendsState> {
  StreamSubscription? _sub;

  FriendsCubit(this._usecases) : super(const FriendsLoading());

  final FriendsUseCases _usecases;
  final _log = logging.Logger('FriendsCubit');

  Future<void> load() async {
    _sub?.cancel();
    _sub = _usecases.friends.listen(
      (friends) {
        if (!isClosed) emit(FriendsLoaded(friends));
      },
      onError: (e, stack) {
        if (!isClosed) {
          _log.warning('Load friends stream error', e, stack);
          emit(FriendsError.from(state, 'Failed to load friends'));
        }
      },
      onDone: () {
        if (!isClosed) emit(FriendsError.from(state, 'Friends stream closed'));
      },
    );
  }

  Future<void> addNpub(String npub) async {
    if (npub.isEmpty) return;

    if (!_usecases.isValidNpub(npub)) {
      emit(FriendsError.from(state, 'Not a valid npub'));
      return;
    }

    final current = _currentFriends;
    emit(FriendsBusy(friends: current, busyNpub: npub, adding: true));

    try {
      await _usecases.add(npub);
    } on ContactException catch (e) {
      if (isClosed) return;
      emit(FriendsError.from(state, e.message));
    } on Exception catch (e, stack) {
      if (isClosed) return;
      _log.warning('Add contact failed', e, stack);
      emit(FriendsError.from(state, 'Could not add contact'));
    }
  }

  Future<void> remove(String npub) async {
    final current = _currentFriends;
    emit(FriendsBusy(friends: current, busyNpub: npub));

    try {
      await _usecases.remove(npub);
    } on Object catch (e, stack) {
      if (isClosed) return;
      _log.warning('Remove contact failed', e, stack);
      emit(FriendsLoaded(current));
    }
  }

  Future<Contact> resolveNpub(String npub) => _usecases.resolve(npub);

  int get contactCount => _currentFriends.length;

  List<Contact> get _currentFriends {
    final s = state;
    if (s is FriendsLoaded) return s.friends;
    if (s is FriendsBusy) return s.friends;
    if (s is FriendsError) return s.friends;
    return const [];
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

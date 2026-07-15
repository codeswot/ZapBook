import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/features/circles/domain/usecases/circles_usecases.dart';
import 'package:zapbook/features/circles/presentation/bloc/circle_members_state.dart';

@injectable
class CircleMembersCubit extends Cubit<CircleMembersState> {
  CircleMembersCubit(
    this._getMyNpubUseCase,
    this._getCircleMembersUseCase,
    this._toggleContactUseCase,
  ) : super(const CircleMembersLoading());

  final GetMyNpubUseCase _getMyNpubUseCase;
  final GetCircleMembersUseCase _getCircleMembersUseCase;
  final ToggleContactUseCase _toggleContactUseCase;

  StreamSubscription<List<Contact>>? _sub;

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }

  String? _circleBookId;

  Future<void> load(String circleBookId, bool isAdmin) async {
    _circleBookId = circleBookId;
    emit(const CircleMembersLoading());

    final myNpub = await _getMyNpubUseCase();

    final circleMembers = await _getCircleMembersUseCase(circleBookId);
    final members = circleMembers
        .map(
          (member) => MemberEntry(
            npub: member.npub,
            contact: member,
            isSelf: member.npub == myNpub,
            isFollow: member.isFollow,
          ),
        )
        .toList();

    await _sub?.cancel();

    emit(CircleMembersLoaded(entries: members, isAdmin: isAdmin));
  }

  Future<void> refresh(String circleBookId) async {
    final currentState = state;
    if (currentState is CircleMembersLoaded) {
      await load(circleBookId, currentState.isAdmin);
    } else if (currentState is CircleMembersBusy) {
      await load(circleBookId, currentState.isAdmin);
    } else {
      await load(circleBookId, false);
    }
  }

  void toggleContact(String npub, bool isFollow) async {
    await _toggleContactUseCase(npub, isFollow);

    if (_circleBookId != null) {
      await refresh(_circleBookId!);
    }
  }
}

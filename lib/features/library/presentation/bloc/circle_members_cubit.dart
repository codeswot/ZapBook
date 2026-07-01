import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:marmot_dart/marmot_dart.dart';

import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/features/library/presentation/bloc/circle_members_state.dart';

@injectable
class CircleMembersCubit extends Cubit<CircleMembersState> {
  CircleMembersCubit(this._marmot, this._contacts, this._identity)
    : super(const CircleMembersLoading());

  final Marmot _marmot;
  final ContactService _contacts;
  final IdentityLocalDataSource _identity;

  StreamSubscription<List<Contact>>? _sub;

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }

  Future<void> load(String circleBookId, bool isAdmin) async {
    emit(const CircleMembersLoading());

    final myNpub = await _identity.readNpub();
    final members = await _marmot.getMembers(circleBookId);
    final memberNpubs = members.map((m) => m.npub).toList();

    await _sub?.cancel();

    _sub = _contacts.watch(memberNpubs).listen((contacts) {
      if (isClosed || state is CircleMembersBusy) return;

      final byNpub = {for (final c in contacts) c.npub: c};
      final contactNpubs = _contacts.stored.toSet();

      final entries = [
        for (final npub in memberNpubs)
          MemberEntry(
            npub: npub,
            contact: byNpub[npub] ?? Contact(npub: npub),
            isSelf: npub == myNpub,
            isContact: contactNpubs.contains(npub),
          ),
      ];
      emit(CircleMembersLoaded(entries: entries, isAdmin: isAdmin));
    });
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

  void toggleContact(String npub, bool isContact) async {
    if (isContact) {
      await _contacts.add(npub);
    } else {
      await _contacts.remove(npub);
    }
  }

  Future<void> removeMember(String circleBookId, String npub) async {
    // Stub
  }
}

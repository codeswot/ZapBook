import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/features/library/domain/usecases/get_book_members.dart';
import 'package:zapbook/features/library/domain/usecases/remove_book_member.dart';
import 'package:zapbook/features/library/presentation/bloc/circle_members_state.dart';

@injectable
class CircleMembersCubit extends Cubit<CircleMembersState> {
  CircleMembersCubit(this._getBookMembers, this._removeBookMember, this._contacts, this._identity)
    : super(const CircleMembersLoading());

  final GetBookMembers _getBookMembers;
  final RemoveBookMember _removeBookMember;
  final ContactService _contacts;
  final IdentityLocalDataSource _identity;

  Future<void> load(String bookId, bool isAdmin) async {
    emit(const CircleMembersLoading());
    final memberNpubs = await _getBookMembers(bookId);
    final contactNpubs = _contacts.stored.toSet();
    final myNpub = await _identity.readNpub();

    final entries = <MemberEntry>[];
    for (final npub in memberNpubs) {
      final contact = await _contacts.resolve(npub);
      entries.add(MemberEntry(
        npub: npub,
        contact: contact,
        isSelf: npub == myNpub,
        isContact: contactNpubs.contains(npub),
      ));
    }

    emit(CircleMembersLoaded(entries: entries, isAdmin: isAdmin));
  }

  Future<void> remove(String bookId, String npub) async {
    final current = state;
    final currentEntries = _extractEntries(current);
    final currentIsAdmin = _extractIsAdmin(current);
    emit(CircleMembersBusy(entries: currentEntries, isAdmin: currentIsAdmin, busyNpub: npub));

    try {
      await _removeBookMember(bookId, npub);
      await load(bookId, currentIsAdmin);
    } on Object {
      emit(CircleMembersLoaded(entries: currentEntries, isAdmin: currentIsAdmin));
    }
  }

  Future<void> addContact(String npub) async {
    final current = state;
    final currentEntries = _extractEntries(current);
    final currentIsAdmin = _extractIsAdmin(current);
    emit(CircleMembersBusy(entries: currentEntries, isAdmin: currentIsAdmin, busyNpub: npub));

    try {
      await _contacts.add(npub);
      final contactNpubs = _contacts.stored.toSet();
      final updated = currentEntries.map((e) => e.isContact ? e : MemberEntry(
        npub: e.npub,
        contact: e.contact,
        isSelf: e.isSelf,
        isContact: contactNpubs.contains(e.npub),
      )).toList();
      emit(CircleMembersLoaded(entries: updated, isAdmin: currentIsAdmin));
    } on Object {
      emit(CircleMembersLoaded(entries: currentEntries, isAdmin: currentIsAdmin));
    }
  }

  List<MemberEntry> _extractEntries(CircleMembersState state) {
    if (state is CircleMembersLoaded) return state.entries;
    if (state is CircleMembersBusy) return state.entries;
    return const [];
  }

  bool _extractIsAdmin(CircleMembersState state) {
    if (state is CircleMembersLoaded) return state.isAdmin;
    if (state is CircleMembersBusy) return state.isAdmin;
    return false;
  }
}

import 'package:zapbook/core/domain/contact.dart';

sealed class CircleMembersState {
  const CircleMembersState();
}

class CircleMembersLoading extends CircleMembersState {
  const CircleMembersLoading();
}

class CircleMembersLoaded extends CircleMembersState {
  const CircleMembersLoaded({required this.entries, required this.isAdmin});
  final List<MemberEntry> entries;
  final bool isAdmin;
}

class CircleMembersBusy extends CircleMembersState {
  const CircleMembersBusy({
    required this.entries,
    required this.isAdmin,
    required this.busyNpub,
  });
  final List<MemberEntry> entries;
  final bool isAdmin;
  final String busyNpub;
}

class MemberEntry {
  final String npub;
  final Contact contact;
  final bool isSelf;
  final bool isContact;

  const MemberEntry({
    required this.npub,
    required this.contact,
    required this.isSelf,
    required this.isContact,
  });
}

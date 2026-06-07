import 'package:zapbook/core/domain/contact.dart';

sealed class ShareCircleState {
  const ShareCircleState();
}

class ShareCircleLoading extends ShareCircleState {
  const ShareCircleLoading();
}

class ShareCircleLoaded extends ShareCircleState {
  const ShareCircleLoaded({required this.friends, required this.selectedNpubs, required this.existingMembers});

  final List<Contact> friends;
  final List<String> selectedNpubs;
  final Set<String> existingMembers;

  bool isExistingMember(String npub) => existingMembers.contains(npub);
}

class ShareCircleBusy extends ShareCircleState {
  const ShareCircleBusy({required this.friends, required this.selectedNpubs, required this.existingMembers, this.adding = false, this.sharing = false});

  final List<Contact> friends;
  final List<String> selectedNpubs;
  final Set<String> existingMembers;
  final bool adding;
  final bool sharing;

  bool isExistingMember(String npub) => existingMembers.contains(npub);
}

import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/features/circles/domain/entities/share_skip.dart';

enum UploadStatus { uploaded, uploading, pending, failed }

sealed class ShareCircleState {
  const ShareCircleState();
}

class ShareCircleLoading extends ShareCircleState {
  const ShareCircleLoading();
}

class ShareCircleLoaded extends ShareCircleState {
  const ShareCircleLoaded({
    required this.friends,
    required this.selectedNpubs,
    required this.existingMembers,
    this.uploadStatus = UploadStatus.uploaded,
    this.shareResult,
  });

  final List<Contact> friends;
  final List<String> selectedNpubs;
  final Set<String> existingMembers;
  final UploadStatus uploadStatus;
  final List<ShareSkip>? shareResult;

  bool isExistingMember(String npub) => existingMembers.contains(npub);
}

class ShareCircleBusy extends ShareCircleState {
  const ShareCircleBusy({
    required this.friends,
    required this.selectedNpubs,
    required this.existingMembers,
    this.uploadStatus = UploadStatus.uploaded,
    this.adding = false,
    this.sharing = false,
  });

  final List<Contact> friends;
  final List<String> selectedNpubs;
  final Set<String> existingMembers;
  final UploadStatus uploadStatus;
  final bool adding;
  final bool sharing;

  bool isExistingMember(String npub) => existingMembers.contains(npub);
}

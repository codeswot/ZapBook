import 'package:zapbook/core/domain/milestone_payload.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/presentation/bloc/circle_members_state.dart'
    show MemberEntry;

sealed class CircleDetailState {
  const CircleDetailState();
}

class CircleDetailLoading extends CircleDetailState {
  const CircleDetailLoading();
}

class CircleDetailLoaded extends CircleDetailState {
  const CircleDetailLoaded({
    required this.book,
    required this.members,
    required this.adminNpubs,
    required this.myNpub,
    this.busyNpub,
    this.processing = false,
    this.milestones = const [],
  });

  final LibraryBook book;
  final List<MemberEntry> members;
  final Set<String> adminNpubs;
  final String? myNpub;
  final String? busyNpub;
  final bool processing;
  final List<MilestonePayload> milestones;

  double get myProgressFraction {
    if (milestones.isEmpty || book.pageCount == 0) return 0;
    final last = milestones.last;
    if (last.totalWordCount <= 0) return 0;
    return (last.currentWordCount / last.totalWordCount).clamp(0.0, 1.0);
  }

  int get myPage {
    if (milestones.isEmpty) return 0;
    return milestones.last.currentPage.clamp(0, book.pageCount);
  }

  bool get isAdmin => myNpub != null && adminNpubs.contains(myNpub);

  bool isMemberAdmin(String npub) => adminNpubs.contains(npub);

  CircleDetailLoaded copyWith({
    LibraryBook? book,
    List<MemberEntry>? members,
    Set<String>? adminNpubs,
    String? busyNpub,
    bool clearBusy = false,
    bool? processing,
    List<MilestonePayload>? milestones,
  }) {
    return CircleDetailLoaded(
      book: book ?? this.book,
      members: members ?? this.members,
      adminNpubs: adminNpubs ?? this.adminNpubs,
      myNpub: myNpub,
      busyNpub: clearBusy ? null : (busyNpub ?? this.busyNpub),
      processing: processing ?? this.processing,
      milestones: milestones ?? this.milestones,
    );
  }
}

class CircleDetailError extends CircleDetailState {
  const CircleDetailError(this.message);

  final String message;
}

class CircleDetailClosed extends CircleDetailState {
  const CircleDetailClosed();
}

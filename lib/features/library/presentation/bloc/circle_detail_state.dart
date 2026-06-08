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
  });

  final LibraryBook book;
  final List<MemberEntry> members;
  final Set<String> adminNpubs;
  final String? myNpub;
  final String? busyNpub;
  final bool processing;

  bool get isAdmin => myNpub != null && adminNpubs.contains(myNpub);

  bool isMemberAdmin(String npub) => adminNpubs.contains(npub);

  CircleDetailLoaded copyWith({
    LibraryBook? book,
    List<MemberEntry>? members,
    Set<String>? adminNpubs,
    String? busyNpub,
    bool clearBusy = false,
    bool? processing,
  }) {
    return CircleDetailLoaded(
      book: book ?? this.book,
      members: members ?? this.members,
      adminNpubs: adminNpubs ?? this.adminNpubs,
      myNpub: myNpub,
      busyNpub: clearBusy ? null : (busyNpub ?? this.busyNpub),
      processing: processing ?? this.processing,
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

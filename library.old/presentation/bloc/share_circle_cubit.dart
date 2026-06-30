import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/features/library/domain/usecases/get_book_members.dart';
import 'package:zapbook/features/library/domain/usecases/share_book_with.dart';
import 'package:zapbook/features/library/domain/entities/share_skip.dart';
import 'package:zapbook/features/library/presentation/bloc/share_circle_state.dart';

@injectable
class ShareCircleCubit extends Cubit<ShareCircleState> {
  ShareCircleCubit(
    this._contacts,
    this._identity,
    this._getBookMembers,
    this._shareBookWith,
  ) : super(const ShareCircleLoading());

  final ContactService _contacts;
  final IdentityLocalDataSource _identity;
  final GetBookMembers _getBookMembers;
  final ShareBookWith _shareBookWith;

  bool isValidNpub(String value) => _contacts.isValidNpub(value);

  Future<void> load(String bookId) async {
    emit(const ShareCircleLoading());
    final friends = await _contacts.friends();
    final myNpub = await _identity.readNpub();
    final members = await _getBookMembers(bookId);
    final existing = members.toSet();

    emit(
      ShareCircleLoaded(
        friends: friends.where((c) => c.npub != myNpub).toList(),
        selectedNpubs: const [],
        existingMembers: existing,
      ),
    );
  }

  void toggleNpub(String npub) {
    final s = _currentLoaded;
    final selected = List<String>.from(s.selectedNpubs);
    if (selected.contains(npub)) {
      selected.remove(npub);
    } else {
      selected.add(npub);
    }
    _emitFrom(s, selectedNpubs: selected);
  }

  Future<void> addNpub(String npub) async {
    final s = _currentLoaded;
    final myNpub = await _identity.readNpub();
    if (npub == myNpub) return;

    emit(
      ShareCircleBusy(
        friends: s.friends,
        selectedNpubs: s.selectedNpubs,
        existingMembers: s.existingMembers,
        adding: true,
      ),
    );

    try {
      final contact = await _contacts.add(npub);
      final friends = s.friends.any((c) => c.npub == npub)
          ? s.friends
          : [contact, ...s.friends];
      final selected = List<String>.from(s.selectedNpubs)..add(npub);
      emit(
        ShareCircleLoaded(
          friends: friends,
          selectedNpubs: selected,
          existingMembers: s.existingMembers,
        ),
      );
    } on Object {
      emit(
        ShareCircleLoaded(
          friends: s.friends,
          selectedNpubs: s.selectedNpubs,
          existingMembers: s.existingMembers,
        ),
      );
    }
  }

  Future<List<ShareSkip>> share(String bookId) async {
    final s = _currentLoaded;
    emit(
      ShareCircleBusy(
        friends: s.friends,
        selectedNpubs: s.selectedNpubs,
        existingMembers: s.existingMembers,
        sharing: true,
      ),
    );
    try {
      final skipped = await _shareBookWith(
        bookId,
        List<String>.from(s.selectedNpubs),
      );
      emit(
        ShareCircleLoaded(
          friends: s.friends,
          selectedNpubs: s.selectedNpubs,
          existingMembers: s.existingMembers,
          shareResult: skipped,
        ),
      );
      return skipped;
    } on Object {
      final allSkipped = s.selectedNpubs
          .map((n) => ShareSkip(npub: n, reason: ShareSkipReason.noKeyPackage))
          .toList();
      emit(
        ShareCircleLoaded(
          friends: s.friends,
          selectedNpubs: s.selectedNpubs,
          existingMembers: s.existingMembers,
          shareResult: allSkipped,
        ),
      );
      return allSkipped;
    }
  }

  ShareCircleLoaded get _currentLoaded {
    final s = state;
    if (s is ShareCircleLoaded) return s;
    if (s is ShareCircleBusy) {
      return ShareCircleLoaded(
        friends: s.friends,
        selectedNpubs: s.selectedNpubs,
        existingMembers: s.existingMembers,
      );
    }
    return const ShareCircleLoaded(
      friends: [],
      selectedNpubs: [],
      existingMembers: {},
    );
  }

  void _emitFrom(ShareCircleLoaded s, {List<String>? selectedNpubs}) {
    emit(
      ShareCircleLoaded(
        friends: s.friends,
        selectedNpubs: selectedNpubs ?? s.selectedNpubs,
        existingMembers: s.existingMembers,
      ),
    );
  }
}

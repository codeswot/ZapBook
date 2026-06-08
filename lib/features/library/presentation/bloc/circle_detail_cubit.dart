import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;

import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/features/library/domain/usecases/dissolve_circle.dart';
import 'package:zapbook/features/library/domain/usecases/get_book_members.dart';
import 'package:zapbook/features/library/domain/usecases/get_circle_admins.dart';
import 'package:zapbook/features/library/domain/usecases/get_library_book.dart';
import 'package:zapbook/features/library/domain/usecases/leave_circle.dart';
import 'package:zapbook/features/library/domain/usecases/remove_book_member.dart';
import 'package:zapbook/features/library/domain/usecases/touch_book_opened.dart';
import 'package:zapbook/features/library/presentation/bloc/circle_detail_state.dart';
import 'package:zapbook/features/library/presentation/bloc/circle_members_state.dart'
    show MemberEntry;

@injectable
class CircleDetailCubit extends Cubit<CircleDetailState> {
  CircleDetailCubit(
    this._getLibraryBook,
    this._getBookMembers,
    this._getCircleAdmins,
    this._removeBookMember,
    this._leaveCircle,
    this._dissolveCircle,
    this._touchBookOpened,
    this._contacts,
    this._identity,
  ) : super(const CircleDetailLoading());

  final GetLibraryBook _getLibraryBook;
  final GetBookMembers _getBookMembers;
  final GetCircleAdmins _getCircleAdmins;
  final RemoveBookMember _removeBookMember;
  final LeaveCircle _leaveCircle;
  final DissolveCircle _dissolveCircle;
  final TouchBookOpened _touchBookOpened;
  final ContactService _contacts;
  final IdentityLocalDataSource _identity;

  final _log = logging.Logger('CircleDetailCubit');

  Future<void> load(String bookId) async {
    final book = await _getLibraryBook(bookId);
    if (book == null) {
      emit(const CircleDetailError('Circle not found'));
      return;
    }

    final myNpub = await _identity.readNpub();
    final memberNpubs = await _getBookMembers(bookId);
    final admins = (await _getCircleAdmins(bookId)).toSet();
    final contactNpubs = _contacts.stored.toSet();

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

    emit(CircleDetailLoaded(
      book: book,
      members: entries,
      adminNpubs: admins,
      myNpub: myNpub,
    ));
  }

  Future<void> refresh(String bookId) => load(bookId);

  void open(String bookId) => _touchBookOpened(bookId);

  Future<void> removeMember(String bookId, String npub) async {
    final s = state;
    if (s is! CircleDetailLoaded) return;
    emit(s.copyWith(busyNpub: npub));
    try {
      await _removeBookMember(bookId, npub);
      await load(bookId);
    } on Object catch (error, stack) {
      _log.warning('Remove member failed', error, stack);
      emit(s.copyWith(clearBusy: true));
    }
  }

  Future<void> leave(String bookId) async {
    final s = state;
    if (s is! CircleDetailLoaded) return;
    emit(s.copyWith(processing: true));
    try {
      await _leaveCircle(bookId);
      emit(const CircleDetailClosed());
    } on Object catch (error, stack) {
      _log.warning('Leave circle failed', error, stack);
      emit(s.copyWith(processing: false));
    }
  }

  Future<void> dissolve(String bookId) async {
    final s = state;
    if (s is! CircleDetailLoaded) return;
    emit(s.copyWith(processing: true));
    try {
      await _dissolveCircle(bookId);
      emit(const CircleDetailClosed());
    } on Object catch (error, stack) {
      _log.warning('Dissolve circle failed', error, stack);
      emit(s.copyWith(processing: false));
    }
  }
}

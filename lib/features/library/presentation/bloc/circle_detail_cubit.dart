import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;

import 'dart:async';

import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/core/services/milestone_service.dart';
import 'package:zapbook/core/services/reading_stats_service.dart';
import 'package:zapbook/core/services/zap_nudge_service.dart';
import 'package:zapbook/core/services/zap_service.dart';
import 'package:zapbook/features/library/domain/repositories/library_repository.dart';
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
    this._milestoneService,
    this._stats,
    this._library,
    this._zapService,
    this._nudgeService,
  ) : super(const CircleDetailLoading()) {
    _library.watchBooks().listen((_) {
      if (!isClosed) refresh(_currentBookId);
    });
  }

  final GetLibraryBook _getLibraryBook;
  final GetBookMembers _getBookMembers;
  final GetCircleAdmins _getCircleAdmins;
  final RemoveBookMember _removeBookMember;
  final LeaveCircle _leaveCircle;
  final DissolveCircle _dissolveCircle;
  final TouchBookOpened _touchBookOpened;
  final ContactService _contacts;
  final IdentityLocalDataSource _identity;
  final MilestoneService _milestoneService;
  final ReadingStatsService _stats;
  final LibraryRepository _library;
  final ZapService _zapService;
  final ZapNudgeService _nudgeService;

  final _log = logging.Logger('CircleDetailCubit');
  String _currentBookId = '';
  StreamSubscription<Map<String, BookProgress>>? _progressSub;

  @override
  Future<void> close() {
    _currentBookId = '';
    _progressSub?.cancel();
    return super.close();
  }

  Future<void> load(String bookId) async {
    _currentBookId = bookId;
    final book = await _getLibraryBook(bookId);
    if (book == null) {
      emit(const CircleDetailError('Circle not found'));
      return;
    }

    final myNpub = await _identity.readNpub();
    final memberNpubs = await _getBookMembers(bookId);
    final admins = (await _getCircleAdmins(bookId)).toSet();
    final contactNpubs = _contacts.stored.toSet();

    final contacts = await Future.wait(memberNpubs.map(_contacts.resolve));
    final entries = [
      for (var i = 0; i < memberNpubs.length; i++)
        MemberEntry(
          npub: memberNpubs[i],
          contact: contacts[i],
          isSelf: memberNpubs[i] == myNpub,
          isContact: contactNpubs.contains(memberNpubs[i]),
        ),
    ];

    final milestones = _milestoneService.getMilestones(bookId);
    final progress = _toMemberProgress(
      await _milestoneService.loadMembers(bookId),
    );
    _watchMembers(bookId);
    emit(
      CircleDetailLoaded(
        book: book,
        members: entries,
        adminNpubs: admins,
        myNpub: myNpub,
        milestones: milestones,
        memberProgress: progress,
        satsEarned: _stats.satsEarned,
      ),
    );
  }

  void _watchMembers(String bookId) {
    _progressSub?.cancel();
    _progressSub = _milestoneService.watchMembers(bookId).listen((members) {
      final s = state;
      if (s is! CircleDetailLoaded) return;
      emit(s.copyWith(memberProgress: _toMemberProgress(members)));
    });
  }

  Map<String, MemberProgress> _toMemberProgress(
    Map<String, BookProgress> members,
  ) => members.map(
    (npub, p) => MapEntry(
      npub,
      MemberProgress(
        currentPage: p.currentPage,
        currentWordCount: p.currentWordCount,
        totalWordCount: p.totalWordCount,
        fraction: p.fraction,
      ),
    ),
  );

  Future<void> refresh(String bookId) => load(bookId);

  void open(String bookId) => _touchBookOpened(bookId);

  Future<ZapResult> sendReaderZap({
    required String recipientLud16,
    required String recipientPubkey,
    required ZapGesture gesture,
    required int amount,
    String? comment,
  }) => _zapService.send(
    recipientLud16: recipientLud16,
    recipientPubkey: recipientPubkey,
    targetEventId: '',
    gesture: gesture,
    customSats: amount,
    comment: comment,
  );

  Future<bool> payInvoice(String invoice) =>
      _zapService.payWithFallback(invoice);

  Future<void> nudgeReader({required String bookId, required String toNpub}) =>
      _nudgeService.nudgeForBook(bookId: bookId, toNpub: toNpub);

  void toggleContact(String npub, bool isContact) {
    if (isContact) {
      _contacts.remove(npub);
    } else {
      _contacts.add(npub);
    }
    final s = state;
    if (s is CircleDetailLoaded) {
      final updated = s.members.map((m) {
        if (m.npub == npub) {
          return MemberEntry(
            npub: m.npub,
            contact: m.contact,
            isSelf: m.isSelf,
            isContact: !isContact,
          );
        }
        return m;
      }).toList();
      emit(s.copyWith(members: updated));
    }
  }

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

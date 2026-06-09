import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;

import 'dart:convert';

import 'package:marmot_dart/marmot_dart.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/core/services/milestone_service.dart';
import 'package:zapbook/core/services/reading_stats_service.dart';
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
    this._marmot,
    this._stats,
    this._library,
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
  final Marmot _marmot;
  final ReadingStatsService _stats;
  final LibraryRepository _library;

  final _log = logging.Logger('CircleDetailCubit');
  String _currentBookId = '';

  @override
  Future<void> close() {
    _currentBookId = '';
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

    final milestones = _milestoneService.getMilestones(bookId);
    final groupId = await _resolveGroupId(bookId);
    final progress = groupId != null
        ? await _fetchMemberProgress(groupId)
        : <String, MemberProgress>{};
    emit(CircleDetailLoaded(
      book: book,
      members: entries,
      adminNpubs: admins,
      myNpub: myNpub,
      milestones: milestones,
      memberProgress: progress,
      satsEarned: _stats.satsEarned,
    ));
  }

  Future<void> refresh(String bookId) => load(bookId);

  void open(String bookId) => _touchBookOpened(bookId);

  Future<String?> _resolveGroupId(String bookId) async {
    try {
      final groups = await _marmot.listGroups();
      final name = 'zapbook-book-$bookId';
      for (final g in groups) {
        if (g.name == name) return g.id;
      }
    } on Object catch (_) {}
    return null;
  }

  Future<Map<String, MemberProgress>> _fetchMemberProgress(
    String groupId,
  ) async {
    final result = <String, MemberProgress>{};
    try {
      final messages = await _marmot.getMessages(groupId);
      for (final msg in messages) {
        final raw = msg.payloadJson;
        if (raw == null || raw.isEmpty) continue;
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) continue;
        final type = decoded['type'];
        final npub = msg.senderNpub;
        int cp, cw, tw;
        if (type == 'zapbook.book.progress') {
          cp = (decoded['currentPage'] as num?)?.toInt() ?? 0;
          cw = (decoded['currentWordCount'] as num?)?.toInt() ?? 0;
          tw = (decoded['totalWordCount'] as num?)?.toInt() ?? 0;
        } else if (type == 'zapbook.book.milestone') {
          cp = (decoded['current_page'] as num?)?.toInt() ?? 0;
          cw = (decoded['current_word_count'] as num?)?.toInt() ?? 0;
          tw = (decoded['total_word_count'] as num?)?.toInt() ?? 0;
        } else {
          continue;
        }
        final existing = result[npub];
        if (existing == null || cp >= existing.currentPage) {
          result[npub] = MemberProgress(
            currentPage: cp,
            currentWordCount: cw,
            totalWordCount: tw,
          );
        }
      }
    } on Object catch (_) {}
    return result;
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

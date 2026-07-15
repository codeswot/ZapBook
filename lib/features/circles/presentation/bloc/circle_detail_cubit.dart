import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';

import 'dart:async';

import 'package:zapbook/features/circles/domain/usecases/circles_usecases.dart';
import 'package:zapbook/features/circles/presentation/bloc/circle_detail_state.dart';
import 'package:zapbook/features/circles/presentation/bloc/circle_members_state.dart'
    show MemberEntry;

@injectable
class CircleDetailCubit extends Cubit<CircleDetailState> {
  CircleDetailCubit(
    this._getCircleBookUseCase,
    this._getMyNpubUseCase,
    this._getCircleMembersUseCase,
    this._watchProgressByBookUseCase,
    this._removeCircleMemberUseCase,
    this._toggleContactUseCase,
    this._leaveCircleBookUseCase,
    this._deleteCircleBookUseCase,
  ) : super(const CircleDetailLoading());

  final GetCircleBookUseCase _getCircleBookUseCase;
  final GetMyNpubUseCase _getMyNpubUseCase;
  final GetCircleMembersUseCase _getCircleMembersUseCase;
  final WatchProgressByBookUseCase _watchProgressByBookUseCase;
  final RemoveCircleMemberUseCase _removeCircleMemberUseCase;
  final ToggleContactUseCase _toggleContactUseCase;
  final LeaveCircleBookUseCase _leaveCircleBookUseCase;
  final DeleteCircleBookUseCase _deleteCircleBookUseCase;

  StreamSubscription? _progressSub;

  Future<void> load(String circleBookId) async {
    final book = await _getCircleBookUseCase(circleBookId);
    if (book == null) {
      emit(const CircleDetailError('Circle not found'));
      return;
    }

    final myNpub = await _getMyNpubUseCase() ?? '';

    final circleMembers = await _getCircleMembersUseCase(circleBookId);

    MemberEntry? selfEntry;
    final otherMembers = <MemberEntry>[];

    for (final member in circleMembers) {
      final isSelf = member.npub == myNpub;
      final entry = MemberEntry(
        npub: member.npub,
        contact: member,
        isSelf: isSelf,
        isFollow: member.isFollow,
      );

      if (isSelf) {
        selfEntry = entry;
      } else {
        otherMembers.add(entry);
      }
    }

    otherMembers.sort((a, b) {
      return a.contact.label.toLowerCase().compareTo(
        b.contact.label.toLowerCase(),
      );
    });

    final members = [...otherMembers, ?selfEntry];

    emit(
      CircleDetailLoaded(
        book: book,
        myNpub: myNpub,
        members: members,
        adminNpubs: book.adminNpubs.toSet(),
        memberProgress: const {},
        milestones: const [],
        satsEarned: 0,
      ),
    );

    _progressSub?.cancel();
    _progressSub =
        _watchProgressByBookUseCase(
          groupId: book.id,
          bookId: book.circleDirId,
        ).listen((progressList) {
          final s = state;
          if (s is CircleDetailLoaded) {
            final newProgress = <String, MemberProgress>{};
            for (final p in progressList) {
              newProgress[p.pubKey] = MemberProgress(
                currentPage: p.pageIndex,
                fraction: p.progressPercentage,
              );
            }
            emit(s.copyWith(memberProgress: newProgress));
          }
        });
  }

  Future<void> refresh(String circleBookId) => load(circleBookId);

  void open(String circleBookId) {}

  Future<void> removeMember(String circleBookId, String npub) async {
    final currentState = state;
    if (currentState is CircleDetailLoaded) {
      await _removeCircleMemberUseCase(circleBookId, npub);
      await refresh(circleBookId);
    }
  }

  Future<void> toggleContact(String npub, bool isFollow) async {
    await _toggleContactUseCase(npub, isFollow);

    final currentState = state;
    if (currentState is CircleDetailLoaded) {
      await refresh(currentState.book.id);
    }
  }

  Future<void> leaveAndDelete(CircleBook circleBook) async {
    final s = state;
    if (s is! CircleDetailLoaded) return;
    await _leaveCircleBookUseCase(circleBook);
    await _deleteCircleBookUseCase(circleBook);
    if (!isClosed) emit(const CircleDetailClosed());
  }

  Future<void> dissolve(CircleBook circleBook) async {
    final s = state;
    if (s is! CircleDetailLoaded) return;

    await _deleteCircleBookUseCase(circleBook);
    if (!isClosed) emit(const CircleDetailClosed());
  }

  @override
  Future<void> close() {
    _progressSub?.cancel();
    return super.close();
  }
}

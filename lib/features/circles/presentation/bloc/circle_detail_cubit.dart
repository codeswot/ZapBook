import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';

import 'dart:async';

import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/circle_store_service.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/core/services/zap_service.dart';
import 'package:zapbook/features/circles/presentation/bloc/circle_detail_state.dart';
import 'package:zapbook/features/circles/presentation/bloc/circle_members_state.dart'
    show MemberEntry;

@injectable
class CircleDetailCubit extends Cubit<CircleDetailState> {
  CircleDetailCubit(this._identityLocal, this._circleStore, this._contacts)
    : super(const CircleDetailLoading());

  final CircleStoreService _circleStore;
  final IdentityLocalDataSource _identityLocal;
  final ContactService _contacts;

  Future<void> load(String circleBookId) async {
    final book = _circleStore.currentCircles
        .where((c) => c.id == circleBookId)
        .firstOrNull;
    if (book == null) {
      emit(const CircleDetailError('Circle not found'));
      return;
    }

    final myNpub = await _identityLocal.readNpub() ?? '';

    final circleMembers = await _circleStore.getCircleMembers(circleBookId);
    final members = circleMembers
        .map(
          (member) => MemberEntry(
            npub: member.npub,
            contact: member,
            isSelf: member.npub == myNpub,
            isFollow: member.isFollow,
          ),
        )
        .toList();

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

    unawaited(syncCircleState(book));
  }

  Future<void> refresh(String circleBookId) => load(circleBookId);

  void open(String circleBookId) {}

  Future<ZapResult> sendReaderZap({
    required String recipientLud16,
    required String recipientPubkey,
    required ZapGesture gesture,
    required int amount,
    String? comment,
  }) async => throw UnimplementedError();

  Future<bool> payZap(ZapResult result) async => false;

  Future<void> zapMember({
    required MemberEntry entry,
    required ZapGesture gesture,
    required int amount,
    String? comment,
    required void Function(String message) onSuccess,
    required void Function(String message) onError,
  }) async {}

  Future<void> notifyZapSent({
    required String recipientNpub,
    required int amount,
    required String reactionType,
  }) async {}

  Future<void> nudgeReader({
    required String circleBookId,
    required String toNpub,
  }) async {}

  Future<void> removeMember(String circleBookId, String npub) async {
    final currentState = state;
    if (currentState is CircleDetailLoaded) {
      await _circleStore.removeCircleMember(circleBookId, npub);
      await refresh(circleBookId);
    }
  }

  Future<void> toggleContact(String npub, bool isFollow) async {
    if (isFollow) {
      await _contacts.remove(npub);
    } else {
      await _contacts.add(npub);
    }

    final currentState = state;
    if (currentState is CircleDetailLoaded) {
      await refresh(currentState.book.id);
    }
  }

  Future<void> leaveAndDelete(CircleBook circleBook) async {
    final s = state;
    if (s is! CircleDetailLoaded) return;
    await _circleStore.leaveCircleBook(circleBook);
    await _circleStore.deleteCircleBook(circleBook);
    if (!isClosed) emit(const CircleDetailClosed());
  }

  Future<void> syncCircleState(CircleBook circleBook) async {
    final s = state;
    if (s is! CircleDetailLoaded) return;
    await _circleStore.syncCircleState(circleBook.id);
  }

  Future<void> dissolve(CircleBook circleBook) async {
    final s = state;
    if (s is! CircleDetailLoaded) return;

    await _circleStore.deleteCircleBook(circleBook);
    if (!isClosed) emit(const CircleDetailClosed());
  }
}

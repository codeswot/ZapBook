import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'dart:async';

import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/services/zap_service.dart';
import 'package:zapbook/features/library/domain/repositories/library_repository.dart';
import 'package:zapbook/features/library/presentation/bloc/circle_detail_state.dart';
import 'package:zapbook/features/library/presentation/bloc/circle_members_state.dart'
    show MemberEntry;

@injectable
class CircleDetailCubit extends Cubit<CircleDetailState> {
  CircleDetailCubit(this._libraryRepository)
    : super(const CircleDetailLoading());

  final LibraryRepository _libraryRepository;

  Future<void> load(String circleBookId) async {
    final book = await _libraryRepository.getBook(circleBookId);
    if (book == null) {
      emit(const CircleDetailError('Circle not found'));
      return;
    }

    emit(
      CircleDetailLoaded(
        book: book,
        members: const [],
        adminNpubs: const {},
        myNpub: '',
        milestones: const [],
        memberProgress: const {},
        satsEarned: 0,
      ),
    );
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

  void toggleContact(String npub, bool isContact) {}

  Future<void> removeMember(String circleBookId, String npub) async {}

  Future<void> leave(String circleBookId) async {}

  Future<void> dissolve(String circleBookId) async {}
}

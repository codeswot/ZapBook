import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/features/library/presentation/bloc/circle_members_state.dart';

@injectable
class CircleMembersCubit extends Cubit<CircleMembersState> {
  CircleMembersCubit() : super(const CircleMembersLoading());

  Future<void> load(String bookId) async {
    emit(const CircleMembersLoaded(members: [], ownerNpub: '', myNpub: ''));
  }

  Future<void> refresh(String bookId) => load(bookId);
  void toggleContact(String npub, bool isContact) {}
  Future<void> removeMember(String bookId, String npub) async {}
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/features/library/domain/entities/share_skip.dart';
import 'package:zapbook/features/library/presentation/bloc/share_circle_state.dart';

@injectable
class ShareCircleCubit extends Cubit<ShareCircleState> {
  ShareCircleCubit() : super(const ShareCircleLoading());

  bool isValidNpub(String value) => false;

  Future<void> load(String circleBookId) async {
    emit(
      const ShareCircleLoaded(
        friends: [],
        selectedNpubs: [],
        existingMembers: {},
      ),
    );
  }

  void toggleNpub(String npub) {}
  Future<void> addNpub(String npub) async {}
  Future<List<ShareSkip>> share(String circleBookId) async => [];
}

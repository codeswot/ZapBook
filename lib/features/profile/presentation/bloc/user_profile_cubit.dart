import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/domain/usecases/clipboard_usecases.dart';
import 'package:zapbook/features/profile/domain/usecases/user_profile_usecases.dart';
import 'package:zapbook/features/profile/presentation/bloc/user_profile_state.dart';

export 'package:zapbook/features/profile/presentation/bloc/user_profile_state.dart';

@injectable
class UserProfileCubit extends Cubit<UserProfileState> {
  UserProfileCubit(this._loadUserProfile, this._copyText)
    : super(const UserProfileLoading());

  final LoadUserProfileUseCase _loadUserProfile;
  final CopyTextUseCase _copyText;

  Future<void> load(String npub) async {
    emit(const UserProfileLoading());
    try {
      emit(UserProfileLoaded(await _loadUserProfile(npub)));
    } on Exception {
      emit(const UserProfileError('Could not load profile'));
    }
  }

  Future<void> copy(String value) => _copyText(value);
}

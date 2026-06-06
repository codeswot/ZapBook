import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/services/clipboard_service.dart';
import 'package:zapbook/features/profile/domain/usecases/load_profile.dart';
import 'package:zapbook/features/profile/domain/usecases/sign_out.dart';
import 'package:zapbook/features/profile/domain/usecases/update_profile.dart';
import 'package:zapbook/features/profile/presentation/bloc/profile_state.dart';

export 'package:zapbook/features/profile/presentation/bloc/profile_state.dart';

@injectable
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(
    this._loadProfile,
    this._updateProfile,
    this._signOut,
    this._clipboard,
  ) : super(const ProfileLoading()) {
    load();
  }

  final LoadProfile _loadProfile;
  final UpdateProfile _updateProfile;
  final SignOut _signOut;
  final ClipboardService _clipboard;

  Future<void> load() async {
    emit(const ProfileLoading());
    try {
      emit(ProfileLoaded(await _loadProfile()));
    } on Object catch (error) {
      emit(ProfileError('$error'));
    }
  }

  Future<void> updateProfile({
    required String displayName,
    required String lud16,
    required String picture,
  }) async {
    final state = this.state;
    if (state is! ProfileLoaded) return;
    final profile = state.profile;
    await _updateProfile(
      npub: profile.npub,
      displayName: displayName,
      lud16: lud16,
      picture: picture,
    );
    await load();
  }

  Future<void> copy(String value) => _clipboard.copy(value);

  Future<void> signOut() => _signOut();
}

import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/config/zapbook_config.dart';
import 'package:zapbook/features/profile/domain/usecases/load_profile.dart';
import 'package:zapbook/features/profile/domain/usecases/profile_usecases.dart';
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
    this._settings,
  ) : super(const ProfileLoading()) {
    load();
  }

  final LoadProfile _loadProfile;
  final UpdateProfile _updateProfile;
  final SignOut _signOut;
  final ProfileSettingsUseCases _settings;

  String? get nwcConnectionString => _settings.nwcConnectionString;
  bool get isNwcConnected => _settings.isNwcConnected;
  String get appVersion => _settings.appVersion;
  String get donationRecipient => ZapbookConfig.lnAddress;
  int get supportPercent => _settings.supportPercent;
  List<int> get supportPercentOptions => _settings.supportPercentOptions;

  Future<void> setSupportPercent(int value) =>
      _settings.setSupportPercent(value);

  Future<void> load() async {
    emit(const ProfileLoading());
    try {
      emit(
        ProfileLoaded(
          await _loadProfile(),
          nwcWalletName: _settings.nwcWalletName,
        ),
      );
    } on Exception catch (error) {
      emit(ProfileError('$error'));
    }
  }

  void _refreshNwc() {
    final state = this.state;
    if (state is ProfileLoaded) {
      emit(
        ProfileLoaded(state.profile, nwcWalletName: _settings.nwcWalletName),
      );
    }
  }

  Future<void> updateProfile({
    required String displayName,
    required String lud16,
    required String picture,
  }) async {
    final state = this.state;
    if (state is! ProfileLoaded) return;
    await _updateProfile(
      displayName: displayName,
      lud16: lud16,
      picture: picture,
    );
    await load();
  }

  Future<String> pickImage() async {
    final bytes = await _settings.pickImage();
    if (bytes != null) {
      return 'data:image/png;base64,${base64Encode(bytes)}';
    }
    return '';
  }

  Future<String?> readNsec() => _settings.readNsec();

  Future<String?> readSignerPackage() => _settings.readSignerPackage();

  Future<void> connectNwc(String uri) async {
    await _settings.connectNwc(uri);
    _refreshNwc();
  }

  Future<void> disconnectNwc() async {
    await _settings.disconnectNwc();
    _refreshNwc();
  }

  Future<void> copy(String value) => _settings.copy(value);

  Future<bool> rotateKeyPackage() => _settings.rotateKeyPackage();

  Future<void> signOut() => _signOut();
}

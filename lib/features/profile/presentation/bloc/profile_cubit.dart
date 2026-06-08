import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/clipboard_service.dart';
import 'package:zapbook/core/services/file_picker_service.dart';
import 'package:zapbook/core/services/nwc_service.dart';
import 'package:zapbook/core/config/zapbook_config.dart';
import 'package:zapbook/core/services/key_package_service.dart';
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
    this._nwc,
    this._identity,
    this._filePicker,
    this._keyPackage,
  ) : super(const ProfileLoading()) {
    load();
  }

  final LoadProfile _loadProfile;
  final UpdateProfile _updateProfile;
  final SignOut _signOut;
  final ClipboardService _clipboard;
  final NwcService _nwc;
  final IdentityLocalDataSource _identity;
  final FilePickerService _filePicker;
  final KeyPackageService _keyPackage;

  String? get nwcConnectionString => _nwc.connectionString;
  String get donationRecipient => ZapbookConfig.lnAddress;

  Future<void> load() async {
    emit(const ProfileLoading());
    try {
      emit(ProfileLoaded(await _loadProfile(), nwcWalletName: _nwc.walletName));
    } on Exception catch (error) {
      emit(ProfileError('$error'));
    }
  }

  void _refreshNwc() {
    final state = this.state;
    if (state is ProfileLoaded) {
      emit(ProfileLoaded(state.profile, nwcWalletName: _nwc.walletName));
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
    final bytes = await _filePicker.pickImage();
    if (bytes != null) {
      return 'data:image/png;base64,${base64Encode(bytes)}';
    }
    return '';
  }

  Future<String?> readNsec() => _identity.readNsec();

  Future<void> connectNwc(String uri) async {
    await _nwc.connect(uri);
    _refreshNwc();
  }

  Future<void> disconnectNwc() async {
    await _nwc.disconnect();
    _refreshNwc();
  }

  Future<void> copy(String value) => _clipboard.copy(value);

  Future<bool> rotateKeyPackage() => _keyPackage.forceRotate();

  Future<void> signOut() => _signOut();
}

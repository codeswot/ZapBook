import 'package:injectable/injectable.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/data/infrastructure/clipboard_service.dart';
import 'package:zapbook/core/data/infrastructure/file_picker_service.dart';
import 'package:zapbook/core/data/infrastructure/app_info_service.dart';
import 'package:zapbook/core/data/infrastructure/nwc_service.dart';
import 'package:zapbook/core/data/infrastructure/key_package_service.dart';
import 'package:zapbook/core/data/infrastructure/zap_support_service.dart';
import 'package:zapbook/features/profile/domain/repositories/profile_settings_repository.dart';

@LazySingleton(as: ProfileSettingsRepository)
class ProfileSettingsRepositoryImpl implements ProfileSettingsRepository {
  final ClipboardService _clipboard;
  final NwcService _nwc;
  final IdentityLocalDataSource _identity;
  final FilePickerService _filePicker;
  final KeyPackageService _keyPackage;
  final AppInfoService _appInfo;
  final ZapSupportService _support;

  ProfileSettingsRepositoryImpl(
    this._clipboard,
    this._nwc,
    this._identity,
    this._filePicker,
    this._keyPackage,
    this._appInfo,
    this._support,
  );

  @override
  String get appVersion => _appInfo.version;
  @override
  String? get nwcConnectionString => _nwc.connectionString;
  @override
  bool get isNwcConnected => _nwc.isConnected;
  @override
  String? get nwcWalletName => _nwc.walletName;
  @override
  int get supportPercent => _support.percent;
  @override
  List<int> get supportPercentOptions => ZapSupportService.options;

  @override
  Future<void> setSupportPercent(int value) => _support.setPercent(value);
  @override
  Future<List<int>?> pickImage() => _filePicker.pickImage();
  @override
  Future<String?> readNsec() => _identity.readNsec();
  @override
  Future<String?> readSignerPackage() async {
    final npub = await _identity.readNpub();
    if (npub == null) return null;
    final meta = await _identity.readSignerMeta(npub);
    return meta != null && meta.isExternal ? meta.package : null;
  }
  @override
  Future<void> connectNwc(String uri) => _nwc.connect(uri);
  @override
  Future<void> disconnectNwc() => _nwc.disconnect();
  @override
  Future<void> copyToClipboard(String value) => _clipboard.copy(value);
  @override
  Future<bool> rotateKeyPackage() => _keyPackage.forceRotate();
}

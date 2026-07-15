import 'package:injectable/injectable.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/data/infrastructure/clipboard_service.dart';
import 'package:zapbook/core/data/infrastructure/file_picker_service.dart';
import 'package:zapbook/core/data/infrastructure/app_info_service.dart';
import 'package:zapbook/core/services/nwc_service.dart';
import 'package:zapbook/core/services/key_package_service.dart';
import 'package:zapbook/core/services/zap_support_service.dart';
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
  Future<void> connectNwc(String uri) => _nwc.connect(uri);
  @override
  Future<void> disconnectNwc() => _nwc.disconnect();
  @override
  Future<void> copyToClipboard(String value) => _clipboard.copy(value);
  @override
  Future<bool> rotateKeyPackage() => _keyPackage.forceRotate();
}

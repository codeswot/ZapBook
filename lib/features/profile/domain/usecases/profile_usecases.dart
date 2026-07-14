import 'package:injectable/injectable.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/data/infrastructure/clipboard_service.dart';
import 'package:zapbook/core/data/infrastructure/file_picker_service.dart';
import 'package:zapbook/core/data/infrastructure/app_info_service.dart';
import 'package:zapbook/core/services/nwc_service.dart';
import 'package:zapbook/core/services/key_package_service.dart';
import 'package:zapbook/core/services/zap_support_service.dart';

// Note: For pragmatic strictness, we group these small operations 
// into a Facade UseCase class for the Profile settings.
@injectable
class ProfileSettingsUseCases {
  final ClipboardService _clipboard;
  final NwcService _nwc;
  final IdentityLocalDataSource _identity;
  final FilePickerService _filePicker;
  final KeyPackageService _keyPackage;
  final AppInfoService _appInfo;
  final ZapSupportService _support;

  ProfileSettingsUseCases(
    this._clipboard,
    this._nwc,
    this._identity,
    this._filePicker,
    this._keyPackage,
    this._appInfo,
    this._support,
  );

  String get appVersion => _appInfo.version;
  String? get nwcConnectionString => _nwc.connectionString;
  bool get isNwcConnected => _nwc.isConnected;
  String get nwcWalletName => _nwc.walletName;
  int get supportPercent => _support.percent;
  List<int> get supportPercentOptions => ZapSupportService.options;

  Future<void> setSupportPercent(int value) => _support.setPercent(value);
  Future<List<int>?> pickImage() => _filePicker.pickImage();
  Future<String?> readNsec() => _identity.readNsec();
  Future<void> connectNwc(String uri) => _nwc.connect(uri);
  Future<void> disconnectNwc() => _nwc.disconnect();
  Future<void> copy(String value) => _clipboard.copy(value);
  Future<bool> rotateKeyPackage() => _keyPackage.forceRotate();
}

import 'package:injectable/injectable.dart';
import 'package:zapbook/features/profile/domain/repositories/profile_settings_repository.dart';

@injectable
class ProfileSettingsUseCases {
  final ProfileSettingsRepository _repository;

  ProfileSettingsUseCases(this._repository);

  String get appVersion => _repository.appVersion;
  String? get nwcConnectionString => _repository.nwcConnectionString;
  bool get isNwcConnected => _repository.isNwcConnected;
  String get nwcWalletName => _repository.nwcWalletName;
  int get supportPercent => _repository.supportPercent;
  List<int> get supportPercentOptions => _repository.supportPercentOptions;

  Future<void> setSupportPercent(int value) => _repository.setSupportPercent(value);
  Future<List<int>?> pickImage() => _repository.pickImage();
  Future<String?> readNsec() => _repository.readNsec();
  Future<void> connectNwc(String uri) => _repository.connectNwc(uri);
  Future<void> disconnectNwc() => _repository.disconnectNwc();
  Future<void> copy(String value) => _repository.copyToClipboard(value);
  Future<bool> rotateKeyPackage() => _repository.rotateKeyPackage();
}

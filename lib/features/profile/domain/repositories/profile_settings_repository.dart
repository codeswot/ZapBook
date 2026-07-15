abstract class ProfileSettingsRepository {
  String get appVersion;
  String? get nwcConnectionString;
  bool get isNwcConnected;
  String? get nwcWalletName;
  int get supportPercent;
  List<int> get supportPercentOptions;

  Future<void> setSupportPercent(int value);
  Future<List<int>?> pickImage();
  Future<String?> readNsec();
  Future<void> connectNwc(String uri);
  Future<void> disconnectNwc();
  Future<void> copyToClipboard(String value);
  Future<bool> rotateKeyPackage();
}

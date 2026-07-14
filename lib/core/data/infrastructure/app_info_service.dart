import 'package:package_info_plus/package_info_plus.dart';

class AppInfoService {
  AppInfoService._(this.version);

  final String version;

  static Future<AppInfoService> init() async {
    final info = await PackageInfo.fromPlatform();
    return AppInfoService._(info.version);
  }
}

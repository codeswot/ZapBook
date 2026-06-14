import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:zapbook/core/identity/active_account.dart';

class AccountPaths {
  AccountPaths._();

  static const accountsDir = 'accounts';

  static Future<Directory> supportRoot() async {
    final base = await getApplicationSupportDirectory();
    return _ensure('${base.path}/$accountsDir/${ActiveAccount.scope}');
  }

  static Future<Directory> cacheRoot() async {
    final base = await getApplicationCacheDirectory();
    return _ensure('${base.path}/$accountsDir/${ActiveAccount.scope}');
  }

  static Future<Directory> _ensure(String path) async {
    final dir = Directory(path);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }
}

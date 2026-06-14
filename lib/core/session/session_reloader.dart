import 'package:injectable/injectable.dart';

import 'package:zapbook/core/session/session_manager.dart';

abstract interface class SessionReloader {
  Future<void> reload();
}

@LazySingleton(as: SessionReloader)
class SessionManagerReloader implements SessionReloader {
  const SessionManagerReloader();

  @override
  Future<void> reload() => reloadSession();
}

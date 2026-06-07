import 'package:injectable/injectable.dart';

import 'package:zapbook/core/services/welcome_inbox_service.dart';

@injectable
final class SyncWelcomes {
  const SyncWelcomes(this._inbox);

  final WelcomeInboxService _inbox;

  Future<int> call() => _inbox.sync();
}

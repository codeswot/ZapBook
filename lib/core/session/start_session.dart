import 'dart:async';

import 'package:logging/logging.dart' as logging;
import 'package:zapbook/core/data/datasources/onboarding_local_datasource.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/identity/nostr_session.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/core/services/key_package_service.dart';
import 'package:zapbook/core/services/nostr_service.dart';
import 'package:zapbook/core/services/reading_stats_service.dart';

Future<void> startSession() async {
  final ok = await getIt<NostrSession>().login();
  if (ok) {
    unawaited(getIt<KeyPackageService>().publishIfNeeded());
    unawaited(getIt<ContactService>().warm());
    await _publishPendingProfile();
  }
  final stats = getIt<ReadingStatsService>();
  unawaited(stats.load().then((_) => stats.publishDailyHeartbeat()));
}

Future<void> _publishPendingProfile() async {
  final store = getIt<OnboardingLocalDataSource>();
  final pending = store.readPendingProfile();
  if (pending == null) return;
  try {
    await getIt<NostrService>().publishMetadata(
      displayName: pending.displayName,
      lud16: pending.lud16,
      picture: pending.picture,
    );
  } on Object catch (error, trace) {
    logging.Logger('startSession').info(error, trace);
  } finally {
    await store.clearPendingProfile();
  }
}

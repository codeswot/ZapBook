import 'dart:async';

import 'package:logging/logging.dart' as logging;
import 'package:zapbook/core/data/datasources/onboarding_local_datasource.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/identity/nostr_session.dart';

import 'package:zapbook/core/data/infrastructure/key_package_service.dart';
import 'package:zapbook/core/data/infrastructure/message_router_service.dart';
import 'package:zapbook/core/data/infrastructure/nostr_service.dart';
import 'package:zapbook/core/data/infrastructure/reading_stats_service.dart';
import 'package:zapbook/core/data/search/search_index_backfill.dart';

Future<void> startSession() async {
  getIt<MessageRouterService>();
  final ok = await getIt<NostrSession>().login();
  if (ok) {
    unawaited(getIt<KeyPackageService>().publishIfNeeded());
    await _publishPendingProfile();
  }
  final stats = getIt<ReadingStatsService>();
  unawaited(stats.load());
  unawaited(getIt<SearchIndexBackfill>().run());
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

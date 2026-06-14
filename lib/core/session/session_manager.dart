import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';

import 'package:zapbook/core/data/cache/nostr_cache_store.dart';
import 'package:zapbook/core/data/search/book_search_index.dart';
import 'package:zapbook/core/data/search/book_vector_index.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/di/marmot_module.dart';
import 'package:zapbook/core/di/nostr_module.dart';
import 'package:zapbook/core/identity/active_account.dart';
import 'package:zapbook/core/identity/nostr_session.dart';
import 'package:zapbook/core/services/marmot_sync_service.dart';
import 'package:zapbook/core/session/start_session.dart';
import 'package:zapbook/widgets/restart_widget.dart';

final _log = logging.Logger('SessionManager');

Future<void> reloadSession() async {
  await _teardown();
  await getIt.reset();
  MarmotWarmup.reset();
  NostrCacheWarmup.reset();
  await ActiveAccount.resolve();
  try {
    await configureDependencies();
    await startSession();
  } on Object catch (error, stack) {
    _log.warning('Session rebuild failed', error, stack);
  } finally {
    RestartWidget.restart();
  }
}

Future<void> _teardown() async {
  await _safe('stop sync', () async => getIt<MarmotSyncService>().stop());
  await _safe('logout', () async => getIt<NostrSession>().logout());
  await _safe('destroy ndk', () async => getIt<Ndk>().destroy());
  await _safe('close cache', () async => getIt<NostrCacheStore>().closeStore());
  await _safe('dispose marmot', () async => getIt<Marmot>().dispose());
  await _safe('close search', () async => getIt<BookSearchIndex>().close());
  await _safe('close vectors', () async => getIt<BookVectorIndex>().close());
}

Future<void> _safe(String label, Future<void> Function() action) async {
  try {
    await action();
  } on Object catch (error) {
    _log.fine('teardown step "$label" skipped: $error');
  }
}

import 'dart:async';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/identity/nostr_session.dart';
import 'package:zapbook/core/observers/app_bloc_observer.dart';
import 'package:zapbook/core/services/ai_service.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/core/services/key_package_service.dart';
import 'package:zapbook/core/services/reading_stats_service.dart';

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    log(
      record.message,
      time: record.time,
      sequenceNumber: record.sequenceNumber,
      level: record.level.value,
      name: record.loggerName,
      zone: record.zone,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  });

  Bloc.observer = AppBlocObserver();
  await configureDependencies();
  await getIt<AiService>().ready;

  try {
    final ok = await getIt<NostrSession>().login();
    if (ok) {
      unawaited(getIt<KeyPackageService>().publishIfNeeded());
      unawaited(getIt<ContactService>().warm());
    }
    unawaited(getIt<ReadingStatsService>().load());
  } on Exception catch (error, stack) {
    Logger.root.warning('NostrSession.login failed at bootstrap', error, stack);
  }

  runApp(await builder());
}

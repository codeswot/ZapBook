import 'dart:async';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:zapbook/core/data/account_migration.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/di/marmot_module.dart';
import 'package:zapbook/core/di/nostr_module.dart';
import 'package:zapbook/core/identity/active_account.dart';
import 'package:zapbook/core/observers/app_bloc_observer.dart';
import 'package:zapbook/core/performance/performance_service.dart';
import 'package:zapbook/core/session/start_session.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

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

  try {
    final prefs = await SharedPreferences.getInstance();
    await AccountMigration.run(prefs);
    await ActiveAccount.resolve();

    unawaited(MarmotWarmup.start());
    unawaited(NostrCacheWarmup.start());
    await configureDependencies();
    await getIt<PerformanceService>().init();
    if (getIt<PerformanceService>().reduceEffects) {
      PaintingBinding.instance.imageCache
        ..maximumSizeBytes = 40 << 20
        ..maximumSize = 120;
    }
    await startSession();
  } on Exception catch (error, stack) {
    Logger.root.warning('Bootstrap setup Error', error, stack);
  }

  runApp(await builder());
}

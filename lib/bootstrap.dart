import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:zapbook/core/di/injection.dart';

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(await builder());
}

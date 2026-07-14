import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/presentation/bloc/book_download/book_download_cubit.dart';
import 'package:zapbook/core/presentation/bloc/performance/performance_cubit.dart';
import 'package:zapbook/core/presentation/router/app_router.dart';
import 'package:zapbook/core/presentation/theme/theme_cubit.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';

class ZapBookApp extends StatelessWidget {
  const ZapBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = getIt<AppRouter>().router;
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => getIt<ThemeCubit>()),
        BlocProvider<PerformanceCubit>(
          create: (_) => getIt<PerformanceCubit>(),
        ),
        BlocProvider<BookDownloadCubit>(
          create: (_) => getIt<BookDownloadCubit>(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'ZapBook',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeMode,
            routerConfig: router,
          );
        },
      ),
    );
  }
}

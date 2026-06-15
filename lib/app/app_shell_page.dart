import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/earnings/earnings_cubit.dart';
import 'package:zapbook/core/router/app_router.dart';
import 'package:zapbook/features/heads_up/presentation/cubit/heads_up_cubit.dart';
import 'package:zapbook/features/heads_up/presentation/widgets/app_headsup_banner.dart';
import 'package:zapbook/features/library/presentation/bloc/page/ingestion_page_cubit.dart';
import 'package:zapbook/features/library/presentation/bloc/library_cubit.dart';
import 'package:zapbook/features/library/presentation/bloc/ingestion_queue_cubit.dart';
import 'package:zapbook/widgets/app_bottom_navigation.dart';

class AppShellPage extends StatelessWidget {
  final Widget child;
  final String location;

  const AppShellPage({super.key, required this.child, required this.location});

  String _getActiveTabId(String location) {
    if (location == '/') return 'home';
    if (location == '/circles') return 'circles';
    if (location == '/cheers') return 'cheers';
    if (location == '/you') return 'you';
    return 'library';
  }

  void _onTabSelected(BuildContext context, String id) {
    if (id == 'home') {
      const HomeRoute().go(context);
    } else if (id == 'circles') {
      const CirclesRoute().go(context);
    } else if (id == 'cheers') {
      const CheersRoute().go(context);
    } else if (id == 'you') {
      const YouRoute().go(context);
    } else if (id == 'library') {
      const LibraryRoute().go(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<EarningsCubit>(create: (_) => getIt<EarningsCubit>()),
        BlocProvider<HeadsUpCubit>(create: (_) => getIt<HeadsUpCubit>()),
        BlocProvider<LibraryCubit>(create: (_) => getIt<LibraryCubit>()),
        BlocProvider<IngestionQueueCubit>(
          create: (_) => getIt<IngestionQueueCubit>(),
        ),
        BlocProvider<IngestionPageCubit>(
          create: (_) => getIt<IngestionPageCubit>(),
        ),
      ],
      child: Scaffold(
        body: Column(
          children: [
            const AppHeadsUpBanner(),
            Expanded(child: child),
          ],
        ),
        bottomNavigationBar: AppBottomNavigation(
          activeId: _getActiveTabId(location),
          onSelected: (id) => _onTabSelected(context, id),
          safeAreaBottom: MediaQuery.of(context).padding.bottom + 8,
        ),
      ),
    );
  }
}

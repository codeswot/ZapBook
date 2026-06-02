import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/features/book_ingestion/presentation/pages/ingestion_page.dart';
import 'package:zapbook/features/book_ingestion/presentation/pages/zbf_viewer_page.dart';
import 'package:zapbook/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:zapbook/features/ai_model/presentation/cubit/ai_model_cubit.dart';
import 'package:zapbook/features/ai_model/presentation/widgets/ai_model_headsup_bridge.dart';
import 'package:zapbook/features/heads_up/presentation/cubit/heads_up_cubit.dart';
import 'package:zapbook/features/heads_up/presentation/widgets/app_headsup_banner.dart';

part 'app_router.g.dart';

@lazySingleton
class AppRouter {
  final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: $appRoutes,
    redirect: (context, state) {
      final prefs = getIt<SharedPreferences>();
      final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!onboardingComplete && !isOnboarding) {
        return '/onboarding';
      }

      if (onboardingComplete && isOnboarding) {
        return '/';
      }

      return null;
    },
  );
}

@TypedGoRoute<OnboardingRoute>(path: '/onboarding')
class OnboardingRoute extends GoRouteData with $OnboardingRoute {
  const OnboardingRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const OnboardingPage();
  }
}

@TypedShellRoute<AppShellRoute>(
  routes: <TypedRoute<RouteData>>[
    TypedGoRoute<IngestionRoute>(path: '/'),
    TypedGoRoute<ZbfViewerRoute>(path: '/viewer'),
  ],
)
class AppShellRoute extends ShellRouteData {
  const AppShellRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AiModelCubit>(create: (_) => getIt<AiModelCubit>()),
        BlocProvider<HeadsUpCubit>(create: (_) => getIt<HeadsUpCubit>()),
      ],
      child: AiModelHeadsUpBridge(
        child: Scaffold(
          body: Column(
            children: [
              const AppHeadsUpBanner(),
              Expanded(child: navigator),
            ],
          ),
        ),
      ),
    );
  }
}

class IngestionRoute extends GoRouteData with $IngestionRoute {
  const IngestionRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const IngestionPage();
  }
}

class ZbfViewerRoute extends GoRouteData with $ZbfViewerRoute {
  final String zbfPath;

  const ZbfViewerRoute({required this.zbfPath});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ZbfViewerPage(zbfPath: zbfPath);
  }
}

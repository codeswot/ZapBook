import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/features/book_ingestion/presentation/pages/ingestion_page.dart';
import 'package:zapbook/features/book_ingestion/presentation/pages/zbf_viewer_page.dart';
import 'package:zapbook/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:zapbook/widgets/app_banner.dart';

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
    return Scaffold(
      body: Column(
        children: [
          const AppBanner(),
          Expanded(child: navigator),
        ],
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
  const ZbfViewerRoute({required this.zbfPath});

  final String zbfPath;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ZbfViewerPage(zbfPath: zbfPath);
  }
}

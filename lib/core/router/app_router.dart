import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:zapbook/app/app_shell_page.dart';
import 'package:zapbook/features/library/presentation/pages/library_page.dart';
import 'package:zapbook/features/library/presentation/pages/circles_page.dart';
import 'package:zapbook/features/library/presentation/pages/circle_detail_page.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/zbf_viewer_page.dart';
import 'package:zapbook/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:zapbook/features/profile/presentation/pages/profile_page.dart';
import 'package:zapbook/features/cheers/presentation/pages/cheers_page.dart';
import 'package:zapbook/features/home/presentation/pages/home_page.dart';

part 'app_router.g.dart';

@lazySingleton
class AppRouter {
  final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: $appRoutes,
    redirect: (context, state) {
      final onboardingComplete = getIt<OnboardingRepository>()
          .status()
          .isComplete;

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
    TypedGoRoute<HomeRoute>(path: '/'),
    TypedGoRoute<CirclesRoute>(path: '/circles'),
    TypedGoRoute<CheersRoute>(path: '/cheers'),
    TypedGoRoute<LibraryRoute>(path: '/library'),
    TypedGoRoute<YouRoute>(path: '/you'),
  ],
)
class AppShellRoute extends ShellRouteData {
  const AppShellRoute();
  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) =>
      AppShellPage(location: state.matchedLocation, child: navigator);
}

class LibraryRoute extends GoRouteData with $LibraryRoute {
  const LibraryRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: const LibraryPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }
}

class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: const HomePage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

class CirclesRoute extends GoRouteData with $CirclesRoute {
  const CirclesRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: const CirclesPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

class CheersRoute extends GoRouteData with $CheersRoute {
  const CheersRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: const CheersPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

class YouRoute extends GoRouteData with $YouRoute {
  const YouRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: const ProfilePage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

@TypedGoRoute<ZbfViewerRoute>(path: '/viewer')
class ZbfViewerRoute extends GoRouteData with $ZbfViewerRoute {
  final String zbfPath;
  final int? page;

  const ZbfViewerRoute({required this.zbfPath, this.page});

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ZbfViewerPage(zbfPath: zbfPath, initialPage: page);
}

@TypedGoRoute<CircleDetailRoute>(path: '/circle')
class CircleDetailRoute extends GoRouteData with $CircleDetailRoute {
  final String bookId;

  const CircleDetailRoute({required this.bookId});

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CircleDetailPage(bookId: bookId);
}

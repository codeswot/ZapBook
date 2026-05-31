import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/features/book_ingestion/presentation/pages/ingestion_page.dart';
import 'package:zapbook/features/book_ingestion/presentation/pages/zbf_viewer_page.dart';

part 'app_router.g.dart';

@lazySingleton
class AppRouter {
  final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: $appRoutes,
  );
}

@TypedGoRoute<IngestionRoute>(
  path: '/',
)
class IngestionRoute extends GoRouteData with $IngestionRoute {
  const IngestionRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const IngestionPage();
  }
}

@TypedGoRoute<ZbfViewerRoute>(
  path: '/viewer',
)
class ZbfViewerRoute extends GoRouteData with $ZbfViewerRoute {
  const ZbfViewerRoute({required this.zbfPath});

  final String zbfPath;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ZbfViewerPage(zbfPath: zbfPath);
  }
}

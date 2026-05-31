// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$ingestionRoute, $zbfViewerRoute];

RouteBase get $ingestionRoute =>
    GoRouteData.$route(path: '/', factory: $IngestionRoute._fromState);

mixin $IngestionRoute on GoRouteData {
  static IngestionRoute _fromState(GoRouterState state) =>
      const IngestionRoute();

  @override
  String get location => GoRouteData.$location('/');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $zbfViewerRoute =>
    GoRouteData.$route(path: '/viewer', factory: $ZbfViewerRoute._fromState);

mixin $ZbfViewerRoute on GoRouteData {
  static ZbfViewerRoute _fromState(GoRouterState state) =>
      ZbfViewerRoute(zbfPath: state.uri.queryParameters['zbf-path']!);

  ZbfViewerRoute get _self => this as ZbfViewerRoute;

  @override
  String get location => GoRouteData.$location(
    '/viewer',
    queryParams: {'zbf-path': _self.zbfPath},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

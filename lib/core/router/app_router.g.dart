// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $onboardingRoute,
  $appShellRoute,
  $zbfViewerRoute,
  $circleDetailRoute,
];

RouteBase get $onboardingRoute => GoRouteData.$route(
  path: '/onboarding',
  factory: $OnboardingRoute._fromState,
);

mixin $OnboardingRoute on GoRouteData {
  static OnboardingRoute _fromState(GoRouterState state) =>
      const OnboardingRoute();

  @override
  String get location => GoRouteData.$location('/onboarding');

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

RouteBase get $appShellRoute => ShellRouteData.$route(
  factory: $AppShellRouteExtension._fromState,
  routes: [
    GoRouteData.$route(path: '/', factory: $HomeRoute._fromState),
    GoRouteData.$route(path: '/circles', factory: $CirclesRoute._fromState),
    GoRouteData.$route(path: '/cheers', factory: $CheersRoute._fromState),
    GoRouteData.$route(path: '/library', factory: $LibraryRoute._fromState),
    GoRouteData.$route(path: '/you', factory: $YouRoute._fromState),
  ],
);

extension $AppShellRouteExtension on AppShellRoute {
  static AppShellRoute _fromState(GoRouterState state) => const AppShellRoute();
}

mixin $HomeRoute on GoRouteData {
  static HomeRoute _fromState(GoRouterState state) => const HomeRoute();

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

mixin $CirclesRoute on GoRouteData {
  static CirclesRoute _fromState(GoRouterState state) => const CirclesRoute();

  @override
  String get location => GoRouteData.$location('/circles');

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

mixin $CheersRoute on GoRouteData {
  static CheersRoute _fromState(GoRouterState state) => const CheersRoute();

  @override
  String get location => GoRouteData.$location('/cheers');

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

mixin $LibraryRoute on GoRouteData {
  static LibraryRoute _fromState(GoRouterState state) => const LibraryRoute();

  @override
  String get location => GoRouteData.$location('/library');

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

mixin $YouRoute on GoRouteData {
  static YouRoute _fromState(GoRouterState state) => const YouRoute();

  @override
  String get location => GoRouteData.$location('/you');

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
  static ZbfViewerRoute _fromState(GoRouterState state) => ZbfViewerRoute(
    zbfPath: state.uri.queryParameters['zbf-path']!,
    page: _$convertMapValue('page', state.uri.queryParameters, int.tryParse),
  );

  ZbfViewerRoute get _self => this as ZbfViewerRoute;

  @override
  String get location => GoRouteData.$location(
    '/viewer',
    queryParams: {
      'zbf-path': _self.zbfPath,
      if (_self.page != null) 'page': _self.page!.toString(),
    },
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

T? _$convertMapValue<T>(
  String key,
  Map<String, String> map,
  T? Function(String) converter,
) {
  final value = map[key];
  return value == null ? null : converter(value);
}

RouteBase get $circleDetailRoute =>
    GoRouteData.$route(path: '/circle', factory: $CircleDetailRoute._fromState);

mixin $CircleDetailRoute on GoRouteData {
  static CircleDetailRoute _fromState(GoRouterState state) =>
      CircleDetailRoute(bookId: state.uri.queryParameters['book-id']!);

  CircleDetailRoute get _self => this as CircleDetailRoute;

  @override
  String get location =>
      GoRouteData.$location('/circle', queryParams: {'book-id': _self.bookId});

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

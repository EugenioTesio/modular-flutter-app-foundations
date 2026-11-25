import 'package:flutter/material.dart';
import 'package:foundations/foundations.dart';
import 'package:go_router/go_router.dart';

import 'example_go_routes.dart';
import 'example_sign_in_guard.dart';

/// An [AppNavigator] over go_router, built from the micro apps' route
/// declarations, as Core does.
///
/// [install] takes what [ModularAppContainer] gathered and checked, and
/// wires two parts, each in its own file: [ExampleGoRoutes] maps the route
/// trees to go_router, and [ExampleSignInGuard] is the `redirect` that sends
/// a signed-out user from a route that requires sign-in to [signInPath],
/// which shows [ExampleSignInRequiredScreen]. A location that matches no
/// route shows [ExampleRouteNotFoundScreen].
///
/// The guard runs on every navigation, including deep links. It is not
/// re-run when the session changes, because the Transfers demo signs out
/// for a moment while its own guarded screen is open. Core's router also
/// refreshes on session changes, so signing out leaves guarded screens.
///
/// go_router's match list is the only record of the stack: [locations] and
/// [popUntil] read it, so nothing can drift from what is on screen. Every
/// screen that closes completes its opener: [pop] through go_router, and
/// [go], [replace], and [popUntil] here, because go_router drops the screens
/// they close without completing their openers.
final class ExampleNavigator implements AppNavigator {
  /// Creates a navigator that guards routes with [session].
  ExampleNavigator({required this.session});

  /// Location of the screen a route that requires sign-in redirects to.
  static const signInPath = '/sign-in';

  /// The signed-in user, read by the redirect on every navigation.
  final SessionContext session;

  /// What [install] produced; `null` until it runs.
  ({List<RouteBase> routes, ExampleSignInGuard guard, String initialLocation})?
  _installation;

  GoRouter? _router;

  /// The go_router instance, for `MaterialApp.router(routerConfig: …)`.
  ///
  /// It is built on first use, after [install]. Throws a [StateError] when
  /// [install] hasn't run.
  GoRouter get router => _router ??= _buildRouter();

  /// Installs the routes the micro apps declared, as they declared them.
  /// The host calls it once, after [ModularAppContainer.bootstrap] has
  /// checked them.
  ///
  /// Parameters:
  /// * [routes] - Every micro app's top-level route nodes, such as
  ///   [ModularAppContainer.routes].
  /// * [requiresAuthentication] - Whether the route with a given full path
  ///   pattern requires sign-in, such as
  ///   [ModularAppContainer.requiresAuthentication].
  /// * [initialLocation] - The location the router opens first.
  void install({
    required List<MicroAppRouteNode> routes,
    required bool? Function(String fullPath) requiresAuthentication,
    required String initialLocation,
  }) {
    _installation = (
      routes: [
        GoRoute(
          path: signInPath,
          builder: (context, state) => const ExampleSignInRequiredScreen(),
        ),
        ...ExampleGoRoutes.fromNodes(routes),
      ],
      guard: ExampleSignInGuard(
        session: session,
        signInPath: signInPath,
        requiresAuthentication: requiresAuthentication,
      ),
      initialLocation: initialLocation,
    );
  }

  /// Paths of the screens on the stack, bottom first, such as
  /// `['/home', '/transfers']`.
  ///
  /// Read from go_router's match list on every call. A route group adds no
  /// entry of its own; its screens do. Query strings are not included.
  List<String> get locations => [
    for (final screen in _screens) screen.matchedLocation,
  ];

  /// Releases the router, if it was built.
  void dispose() => _router?.dispose();

  GoRouter _buildRouter() {
    final installation = _installation;
    if (installation == null) {
      throw StateError('Call install before using the router.');
    }
    return GoRouter(
      initialLocation: installation.initialLocation,
      routes: installation.routes,
      redirect: installation.guard.redirect,
      errorBuilder: (context, state) =>
          ExampleRouteNotFoundScreen(location: state.uri.toString()),
    );
  }

  /// Whether [path] parses and matches a declared route.
  bool _matches(String path) {
    final uri = Uri.tryParse(path);
    return uri != null && !router.configuration.findMatch(uri).isError;
  }

  static NavigationResult _outcome(Object? result) =>
      result is Map<String, Object>
      ? RouteCompleted(result)
      : const RouteCancelled();

  /// The screens in go_router's current match list, bottom first.
  List<RouteMatch> get _screens =>
      _screensIn(router.routerDelegate.currentConfiguration.matches).toList();

  /// Flattens [matches] to the screens they show. A group's match is not a
  /// screen, so it is replaced by the screens inside it.
  static Iterable<RouteMatch> _screensIn(List<RouteMatchBase> matches) sync* {
    for (final match in matches) {
      switch (match) {
        case ShellRouteMatch(:final matches):
          yield* _screensIn(matches);
        case RouteMatch():
          yield match;
      }
    }
  }

  /// Runs [navigate], then completes with `null`, which the opener reads as
  /// [RouteCancelled], every pushed screen that [navigate] removed from the
  /// stack. go_router drops those screens without completing their openers,
  /// which would otherwise wait forever.
  void _cancelClosedScreens(void Function() navigate) {
    final before = _screens.whereType<ImperativeRouteMatch>().toList();
    navigate();
    final open = {
      for (final screen in _screens.whereType<ImperativeRouteMatch>())
        screen.completer,
    };
    for (final screen in before) {
      if (!open.contains(screen.completer) && !screen.completer.isCompleted) {
        screen.complete();
      }
    }
  }

  @override
  Future<Result<NavigationResult, NavigationException>> push(
    String path, {
    Map<String, Object> body = const {},
  }) async {
    if (!_matches(path)) return Err(RouteNotFoundException(path));
    final result = await router.push<Object?>(path, extra: body);
    return Ok(_outcome(result));
  }

  @override
  Result<void, NavigationException> go(
    String path, {
    Map<String, Object> body = const {},
  }) {
    if (!_matches(path)) return Err(RouteNotFoundException(path));
    _cancelClosedScreens(() => router.go(path, extra: body));
    return const Ok(null);
  }

  @override
  Future<Result<NavigationResult, NavigationException>> replace(
    String path, {
    Map<String, Object> body = const {},
  }) async {
    if (!_matches(path)) return Err(RouteNotFoundException(path));
    final stack = router.routerDelegate.currentConfiguration;
    if (stack.isEmpty || stack.remove(stack.last).isEmpty) {
      // go_router replaces the only screen the way go does and never
      // completes the call. The new screen is then the first one, which
      // can't be closed, so the call completes now.
      _cancelClosedScreens(() => router.go(path, extra: body));
      return const Ok(RouteCancelled());
    }
    late final Future<Object?> result;
    _cancelClosedScreens(
      () => result = router.pushReplacement<Object?>(path, extra: body),
    );
    return Ok(_outcome(await result));
  }

  @override
  void pop({Map<String, Object>? result}) {
    if (router.canPop()) router.pop(result);
  }

  @override
  Result<void, NavigationException> popUntil(String path) {
    final target = Uri.tryParse(path)?.path;
    final screens = _screens;
    final index = screens.lastIndexWhere(
      (screen) => screen.matchedLocation == target,
    );
    if (index == -1) return Err(RouteNotFoundException(path));
    if (index == screens.length - 1) return const Ok(null);
    // Cuts the match list in one step instead of popping screen by screen:
    // until the next frame, go_router's pages still point at the matches
    // they were built from, so a second pop that leaves a group completes
    // an opener twice. RouteMatchList.remove drops a screen and every screen
    // above it.
    final stack = router.routerDelegate.currentConfiguration;
    _cancelClosedScreens(
      () => router.restore(stack.remove(screens[index + 1])),
    );
    return const Ok(null);
  }
}

/// The screen a route that requires sign-in redirects to while no user is
/// signed in. The example has no sign-in micro app, so it only explains why
/// the screen can't open; closing it cancels the navigation.
class ExampleSignInRequiredScreen extends StatelessWidget {
  /// Creates the screen.
  const ExampleSignInRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DsPageScaffold(
      title: 'Sign in',
      body: DsEmptyState(
        icon: Icons.lock_outline,
        title: 'Sign in to continue',
        message: 'This screen is available after you sign in.',
      ),
    );
  }
}

/// The host's screen for a location that matches no route, such as a broken
/// deep link.
class ExampleRouteNotFoundScreen extends StatelessWidget {
  /// Creates the screen for [location].
  const ExampleRouteNotFoundScreen({super.key, required this.location});

  /// The location that matched no route.
  final String location;

  @override
  Widget build(BuildContext context) {
    return DsPageScaffold(
      title: 'Not found',
      body: DsEmptyState(
        icon: Icons.explore_off_outlined,
        title: 'This screen does not exist',
        message: 'Nothing is available at $location.',
      ),
    );
  }
}

// Reference adapter from the router-neutral route contract to go_router, and
// an AppNavigator on top of it (contracts/routing.md, "How Core implements
// it"). Dev-only: go_router is a dev dependency, and Core owns the real
// adapter. This proves the contract maps onto a real router (SC-015).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:foundations/foundations.dart';
import 'package:go_router/go_router.dart';

/// Builds a [GoRouter] from route trees and navigates through it.
final class ReferenceRouter implements AppNavigator {
  /// Creates a router over [routes] (every micro app's top-level nodes),
  /// starting at [initialLocation].
  ///
  /// A route for which `requiresAuthentication` returns `true` (given its
  /// full path pattern, as [ModularAppContainer.requiresAuthentication]
  /// does) redirects to `signInPath` while `session` is [Unauthenticated],
  /// and is re-checked whenever the session changes. A deep link that
  /// matches no route shows a plain not-found screen.
  ReferenceRouter({
    required List<MicroAppRouteNode> routes,
    required this._requiresAuthentication,
    required this._session,
    required this._signInPath,
    required String initialLocation,
  }) {
    _sessionChanges = _session.changes.listen((_) => router.refresh());
    router = GoRouter(
      initialLocation: initialLocation,
      routes: [for (final node in routes) _toRouteBase(node)],
      redirect: _redirect,
      errorBuilder: (context, state) =>
          _defaultNotFound(context, state.uri.toString()),
    );
  }

  /// The go_router instance, for `MaterialApp.router(routerConfig: …)`.
  late final GoRouter router;

  final SessionContext _session;
  final String _signInPath;
  final bool? Function(String fullPath) _requiresAuthentication;
  late final StreamSubscription<SessionState> _sessionChanges;

  /// The location currently shown, after redirects.
  String get currentLocation =>
      router.routerDelegate.currentConfiguration.uri.toString();

  /// Paths of the screens on the stack, bottom first, read from go_router's
  /// match list on every call. go_router's match list is the only record of
  /// the stack, so nothing can drift from what is on screen.
  List<String> get stack => [
    for (final screen in _screens) screen.matchedLocation,
  ];

  /// Releases the session subscription and the router.
  Future<void> dispose() async {
    await _sessionChanges.cancel();
    router.dispose();
  }

  // -------------------------------------------------------------------------
  // Route mapping
  // -------------------------------------------------------------------------

  RouteBase _toRouteBase(MicroAppRouteNode node) => switch (node) {
    MicroAppRoute() => GoRoute(
      path: node.path,
      pageBuilder: (context, state) => MaterialPage<Object?>(
        key: state.pageKey,
        fullscreenDialog:
            node.presentation == RoutePresentation.fullscreenDialog,
        child: node.builder(context, {
          ...state.pathParameters,
          ...state.uri.queryParameters,
        }, _bodyOf(state.extra)),
      ),
      routes: [for (final child in node.routes) _toRouteBase(child)],
    ),
    MicroAppRouteGroup() => ShellRoute(
      builder: (context, state, child) => node.builder(context, child),
      routes: [for (final child in node.routes) _toRouteBase(child)],
    ),
  };

  static Map<String, Object> _bodyOf(Object? extra) =>
      extra is Map<String, Object> ? extra : const {};

  String? _redirect(BuildContext context, GoRouterState state) {
    final fullPath = state.fullPath;
    if (fullPath == null) return null;
    final needsSignIn = _requiresAuthentication(fullPath) ?? false;
    if (needsSignIn && _session.current is Unauthenticated) return _signInPath;
    return null;
  }

  static Widget _defaultNotFound(BuildContext context, String location) =>
      Scaffold(body: Center(child: Text('No screen at $location')));

  bool _matches(String path) {
    final uri = Uri.tryParse(path);
    return uri != null && !router.configuration.findMatch(uri).isError;
  }

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

  /// Runs [navigate], then completes with `null` (read as [RouteCancelled])
  /// every pushed screen it removed. go_router drops those screens without
  /// completing their openers, which would otherwise wait forever.
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

  // -------------------------------------------------------------------------
  // AppNavigator
  // -------------------------------------------------------------------------

  @override
  Future<Result<NavigationResult, NavigationException>> push(
    String path, {
    Map<String, Object> body = const {},
  }) async {
    if (!_matches(path)) return Err(RouteNotFoundException(path));
    final result = await router.push<Object?>(path, extra: body);
    return Ok(_outcomeOf(result));
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
    return Ok(_outcomeOf(await result));
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

  static NavigationResult _outcomeOf(Object? result) =>
      result is Map<String, Object>
      ? RouteCompleted(result)
      : const RouteCancelled();
}

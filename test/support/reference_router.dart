// Reference adapter from the router-neutral route contract to go_router, and
// an AppNavigator on top of it (contracts/routing.md, "How Core implements
// it"). Dev-only: go_router is a dev dependency, and Core owns the real
// adapter. This proves the contract maps onto a real router (SC-015).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:foundations/foundations.dart';
import 'package:go_router/go_router.dart';

import 'reference_route_validation.dart';

/// Builds a [GoRouter] from route trees and navigates through it.
final class ReferenceRouter implements AppNavigator {
  /// Creates a router over [routes] (every micro app's top-level nodes),
  /// starting at [initialLocation].
  ///
  /// Routes that require sign-in redirect to `signInPath` while `session` is
  /// [Unauthenticated], and are re-checked whenever the session changes.
  /// A deep link that matches no route shows [notFoundBuilder].
  ReferenceRouter({
    required List<MicroAppRouteNode> routes,
    required this._session,
    required this._signInPath,
    required String initialLocation,
    Widget Function(BuildContext context, String location)? notFoundBuilder,
  }) {
    _requiresAuth = {
      for (final entry in ReferenceRouteValidation.flatten(routes))
        entry.fullPath: entry.requiresAuthentication,
    };
    _sessionChanges = _session.changes.listen((_) => router.refresh());
    _stack.add(_StackEntry(initialLocation));
    router = GoRouter(
      initialLocation: initialLocation,
      routes: [for (final node in routes) _toRouteBase(node)],
      redirect: _redirect,
      errorBuilder: (context, state) =>
          (notFoundBuilder ?? _defaultNotFound)(context, state.uri.toString()),
    );
  }

  /// The go_router instance, for `MaterialApp.router(routerConfig: …)`.
  late final GoRouter router;

  final SessionContext _session;
  final String _signInPath;
  late final Map<String, bool> _requiresAuth;
  late final StreamSubscription<SessionState> _sessionChanges;

  // The locations opened through this navigator, bottom first. go_router's
  // own stack is not public API, so the adapter keeps a mirror of it.
  final List<_StackEntry> _stack = [];

  /// The location currently shown, after redirects.
  String get currentLocation =>
      router.routerDelegate.currentConfiguration.uri.toString();

  /// The locations opened through this navigator, bottom first.
  List<String> get stack => [for (final entry in _stack) entry.location];

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
    final needsSignIn = _requiresAuth[fullPath] ?? false;
    if (needsSignIn && _session.current is Unauthenticated) return _signInPath;
    return null;
  }

  static Widget _defaultNotFound(BuildContext context, String location) =>
      Scaffold(body: Center(child: Text('No screen at $location')));

  bool _matches(String path) =>
      !router.configuration.findMatch(Uri.parse(path)).isError;

  // -------------------------------------------------------------------------
  // AppNavigator
  // -------------------------------------------------------------------------

  @override
  Future<Result<NavigationResult, NavigationException>> push(
    String path, {
    Map<String, Object> body = const {},
  }) async {
    if (!_matches(path)) return Err(RouteNotFoundException(path));
    final entry = _StackEntry(path);
    _stack.add(entry);
    final result = await router.push<Object?>(path, extra: body);
    _stack.remove(entry);
    return Ok(_outcomeOf(result));
  }

  @override
  Result<void, NavigationException> go(
    String path, {
    Map<String, Object> body = const {},
  }) {
    if (!_matches(path)) return Err(RouteNotFoundException(path));
    _stack
      ..clear()
      ..add(_StackEntry(path));
    router.go(path, extra: body);
    return const Ok(null);
  }

  @override
  Future<Result<NavigationResult, NavigationException>> replace(
    String path, {
    Map<String, Object> body = const {},
  }) async {
    if (!_matches(path)) return Err(RouteNotFoundException(path));
    final entry = _StackEntry(path);
    if (_stack.isNotEmpty) _stack.removeLast();
    _stack.add(entry);
    final result = await router.pushReplacement<Object?>(path, extra: body);
    _stack.remove(entry);
    return Ok(_outcomeOf(result));
  }

  @override
  void pop({Map<String, Object>? result}) {
    if (_stack.length > 1) _stack.removeLast();
    router.pop(result);
  }

  @override
  Result<void, NavigationException> popUntil(String path) {
    if (!_stack.any((entry) => entry.location == path)) {
      return Err(RouteNotFoundException(path));
    }
    while (_stack.last.location != path) {
      _stack.removeLast();
      router.pop();
    }
    return const Ok(null);
  }

  static NavigationResult _outcomeOf(Object? result) =>
      result is Map<String, Object>
      ? RouteCompleted(result)
      : const RouteCancelled();
}

// Identity matters: the same location may be on the stack twice.
final class _StackEntry {
  _StackEntry(this.location);

  final String location;
}

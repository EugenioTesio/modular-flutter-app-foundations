import 'package:flutter/material.dart';
import 'package:foundations/foundations.dart';

/// An [AppNavigator] over Flutter's [Navigator], built from the micro apps'
/// route declarations.
///
/// Core uses a full router; this example keeps to plain [Navigator] so the
/// host stays short. It supports top-level and nested routes with `:name`
/// parameters and query parameters, groups (their layout wraps each screen),
/// and full-screen dialogs. It does not guard routes by sign-in state.
final class ExampleNavigator implements AppNavigator {
  /// Key of the app's root navigator; pass it to `MaterialApp.navigatorKey`.
  final navigatorKey = GlobalKey<NavigatorState>();

  /// Observer that tracks the stack for [popUntil]; pass it to
  /// `MaterialApp.navigatorObservers`.
  late final NavigatorObserver observer = _StackObserver(_stack);

  final _stack = <String>[];
  var _routes = <_RouteEntry>[];

  /// Installs every route the micro apps declared. The host calls it once,
  /// after every micro app has initialized.
  void install(Iterable<MicroAppRouteNode> nodes) {
    _routes = [..._RouteEntry.flatten(nodes, parent: '', layouts: const [])];
  }

  /// Builds the page for a location, or null when no route matches.
  ///
  /// Pass it to `MaterialApp.onGenerateRoute`; the body travels in
  /// [RouteSettings.arguments].
  Route<Map<String, Object>?>? onGenerateRoute(RouteSettings settings) {
    final location = Uri.parse(settings.name ?? '');
    for (final entry in _routes) {
      final parameters = entry.match(location);
      if (parameters == null) continue;
      final body = settings.arguments is Map<String, Object>
          ? settings.arguments! as Map<String, Object>
          : const <String, Object>{};
      return MaterialPageRoute<Map<String, Object>?>(
        settings: settings,
        fullscreenDialog:
            entry.route.presentation == RoutePresentation.fullscreenDialog,
        builder: (context) => entry.layouts.reversed.fold(
          entry.route.builder(context, parameters, body),
          (child, layout) => layout(context, child),
        ),
      );
    }
    return null;
  }

  bool _matches(String path) =>
      _routes.any((entry) => entry.match(Uri.parse(path)) != null);

  NavigatorState get _navigator => navigatorKey.currentState!;

  static NavigationResult _outcome(Map<String, Object>? result) =>
      result == null ? const RouteCancelled() : RouteCompleted(result);

  @override
  Future<Result<NavigationResult, NavigationException>> push(
    String path, {
    Map<String, Object> body = const {},
  }) async {
    if (!_matches(path)) return Err(RouteNotFoundException(path));
    final result = await _navigator.pushNamed<Map<String, Object>?>(
      path,
      arguments: body,
    );
    return Ok(_outcome(result));
  }

  @override
  Result<void, NavigationException> go(
    String path, {
    Map<String, Object> body = const {},
  }) {
    if (!_matches(path)) return Err(RouteNotFoundException(path));
    _navigator.pushNamedAndRemoveUntil(path, (_) => false, arguments: body);
    return const Ok(null);
  }

  @override
  Future<Result<NavigationResult, NavigationException>> replace(
    String path, {
    Map<String, Object> body = const {},
  }) async {
    if (!_matches(path)) return Err(RouteNotFoundException(path));
    final result = await _navigator
        .pushReplacementNamed<Map<String, Object>?, Object?>(
          path,
          arguments: body,
        );
    return Ok(_outcome(result));
  }

  @override
  void pop({Map<String, Object>? result}) => _navigator.maybePop(result);

  @override
  Result<void, NavigationException> popUntil(String path) {
    if (!_stack.contains(path)) return Err(RouteNotFoundException(path));
    _navigator.popUntil((route) => route.settings.name == path);
    return const Ok(null);
  }
}

typedef _Layout = Widget Function(BuildContext context, Widget child);

final class _RouteEntry {
  _RouteEntry(this.fullPath, this.route, this.layouts)
    : _segments = Uri.parse(fullPath).pathSegments;

  final String fullPath;
  final MicroAppRoute route;
  final List<_Layout> layouts;
  final List<String> _segments;

  static Iterable<_RouteEntry> flatten(
    Iterable<MicroAppRouteNode> nodes, {
    required String parent,
    required List<_Layout> layouts,
  }) sync* {
    for (final node in nodes) {
      switch (node) {
        case MicroAppRoute(:final path, :final routes):
          final full = path.startsWith('/')
              ? path
              : '${parent == '/' ? '' : parent}/$path';
          yield _RouteEntry(full, node, layouts);
          yield* flatten(routes, parent: full, layouts: layouts);
        case MicroAppRouteGroup(:final builder, :final routes):
          yield* flatten(
            routes,
            parent: parent,
            layouts: [...layouts, builder],
          );
      }
    }
  }

  /// The path and query parameters when [location] matches, else null.
  Map<String, String>? match(Uri location) {
    final segments = location.pathSegments;
    if (segments.length != _segments.length) return null;
    final parameters = <String, String>{...location.queryParameters};
    for (var i = 0; i < segments.length; i++) {
      final pattern = _segments[i];
      if (pattern.startsWith(':')) {
        if (segments[i].isEmpty) return null;
        parameters[pattern.substring(1)] = segments[i];
      } else if (pattern != segments[i]) {
        return null;
      }
    }
    return parameters;
  }
}

final class _StackObserver extends NavigatorObserver {
  _StackObserver(this._stack);

  final List<String> _stack;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stack.add(route.settings.name ?? '');

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stack.removeLast();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stack.remove(route.settings.name ?? '');

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = _stack.lastIndexOf(oldRoute?.settings.name ?? '');
    if (index >= 0) _stack[index] = newRoute?.settings.name ?? '';
  }
}

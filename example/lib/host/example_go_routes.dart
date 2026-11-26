import 'package:flutter/material.dart';
import 'package:foundations/foundations.dart';
import 'package:go_router/go_router.dart';

/// The mapping from the router-neutral route declarations to go_router, as
/// static helpers.
///
/// Each [MicroAppRoute] becomes a [GoRoute] and each [MicroAppRouteGroup] a
/// [ShellRoute], so a group's layout stays in place while the user moves
/// between its routes. It maps only; the checks run before it, in
/// [ModularAppContainer.bootstrap].
abstract final class ExampleGoRoutes {
  /// Maps [nodes] and their children to go_router routes.
  ///
  /// Parameters:
  /// * [nodes] - The route nodes to map.
  ///
  /// The builder gets path and query parameters merged into one map, and
  /// the `push` body, which go_router carries as `extra`. A full-screen
  /// dialog route opens as a full-screen page.
  static List<RouteBase> fromNodes(Iterable<MicroAppRouteNode> nodes) => [
    for (final node in nodes) _fromNode(node),
  ];

  static RouteBase _fromNode(MicroAppRouteNode node) => switch (node) {
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
      routes: fromNodes(node.routes),
    ),
    MicroAppRouteGroup() => ShellRoute(
      builder: (context, state, child) => node.builder(context, child),
      routes: fromNodes(node.routes),
    ),
  };

  /// The body a caller passed as go_router's `extra`; a deep link has none.
  static Map<String, Object> _bodyOf(Object? extra) =>
      extra is Map<String, Object> ? extra : const {};
}

/// @docImport 'modular_app_container.dart';
library;

import '../exceptions/modular_app_startup_exception.dart';
import '../routing/micro_app_route.dart';

/// Value that describes one declared route, looked up by its full path.
///
/// Holds the micro app that declared the route and whether the route
/// requires sign-in, its own flag or any ancestor's.
typedef ModularAppRouteFacts = ({
  String microAppId,
  bool requiresAuthentication,
});

/// Startup checks on the micro apps' route trees, as static helpers.
///
/// Use this through [ModularAppContainer.bootstrap]; it is not exported.
///
/// This is **not** a router mapping: it only reads the trees, and never
/// flattens, merges, or rewrites what a micro app declared.
abstract final class ModularAppRouteChecks {
  /// Checks every micro app's route tree and returns the facts of each
  /// route, keyed by full path.
  ///
  /// Parameters:
  /// * [routesByMicroApp] - Each micro app's top-level route nodes, keyed by
  ///   micro app id.
  /// * [hostPaths] - Paths the host keeps for itself, such as `/sign-in`;
  ///   defaults to none.
  ///
  /// A full path joins a route's path to its ancestors' paths, as go_router
  /// does: `/accounts` and `details/:accountId` give
  /// `/accounts/details/:accountId`. Paths directly in a
  /// [MicroAppRouteGroup] are absolute and start again.
  ///
  /// Throws a [ModularAppStartupException] naming the path and the micro app
  /// when:
  /// * a top-level path, or a path directly in a group, doesn't start with
  ///   `/<microAppId>`, or a nested path starts with `/`
  ///   ([ModularAppStartupExceptionType.invalidRoutePath]);
  /// * a full path repeats a parameter name
  ///   ([ModularAppStartupExceptionType.repeatedPathParameter]);
  /// * two routes share a full path, parameter names aside
  ///   ([ModularAppStartupExceptionType.duplicateRoutePath]);
  /// * a route takes one of [hostPaths]
  ///   ([ModularAppStartupExceptionType.reservedRoutePath]).
  static Map<String, ModularAppRouteFacts> check(
    Map<String, List<MicroAppRouteNode>> routesByMicroApp, {
    Set<String> hostPaths = const {},
  }) {
    final facts = <String, ModularAppRouteFacts>{};
    final hostShapes = {for (final path in hostPaths) _shapeOf(path): path};
    // shape -> (full path, micro app id)
    final owners = <String, (String, String)>{};
    for (final MapEntry(key: id, value: routes) in routesByMicroApp.entries) {
      _walk(
        routes,
        parentPath: null,
        parentRequiresAuthentication: false,
        visit: (route, fullPath, requiresAuthentication) {
          _checkForm(id, route.path, fullPath);
          _checkParameters(id, fullPath);
          final shape = _shapeOf(fullPath);
          final hostPath = hostShapes[shape];
          if (hostPath != null) {
            throw ModularAppStartupException(
              type: ModularAppStartupExceptionType.reservedRoutePath,
              message:
                  'Route path "$fullPath" of "$id" is reserved by the host '
                  '("$hostPath").',
            );
          }
          final previous = owners[shape];
          if (previous != null) {
            final (path, owner) = previous;
            throw ModularAppStartupException(
              type: ModularAppStartupExceptionType.duplicateRoutePath,
              message:
                  'Duplicate route path "$fullPath" declared by "$id"; '
                  '"$owner" already declares "$path".',
            );
          }
          owners[shape] = (fullPath, id);
          facts[fullPath] = (
            microAppId: id,
            requiresAuthentication: requiresAuthentication,
          );
        },
      );
    }
    return facts;
  }

  /// Walks [nodes] depth first and calls [visit] for every route with its
  /// full path and effective sign-in requirement.
  static void _walk(
    List<MicroAppRouteNode> nodes, {
    required String? parentPath,
    required bool parentRequiresAuthentication,
    required void Function(
      MicroAppRoute route,
      String fullPath,
      bool requiresAuthentication,
    )
    visit,
  }) {
    for (final node in nodes) {
      switch (node) {
        case MicroAppRoute():
          final fullPath = parentPath == null
              ? node.path
              : _join(parentPath, node.path);
          final requiresAuthentication =
              parentRequiresAuthentication || node.requiresAuthentication;
          visit(node, fullPath, requiresAuthentication);
          _walk(
            node.routes,
            parentPath: fullPath,
            parentRequiresAuthentication: requiresAuthentication,
            visit: visit,
          );
        case MicroAppRouteGroup():
          // Grouped routes use absolute paths, so they restart the join.
          _walk(
            node.routes,
            parentPath: null,
            parentRequiresAuthentication: parentRequiresAuthentication,
            visit: visit,
          );
      }
    }
  }

  static String _join(String parent, String child) =>
      parent.endsWith('/') ? '$parent$child' : '$parent/$child';

  /// Checks the prefix rule. Only a top-level path, or a path directly in a
  /// group, has a full path equal to its own path: a nested path is always
  /// joined to its parent's.
  static void _checkForm(String id, String path, String fullPath) {
    if (path == fullPath) {
      if (path != '/$id' && !path.startsWith('/$id/')) {
        throw ModularAppStartupException(
          type: ModularAppStartupExceptionType.invalidRoutePath,
          message:
              'Top-level route path "$path" of "$id" must start with "/$id".',
        );
      }
    } else if (path.startsWith('/')) {
      throw ModularAppStartupException(
        type: ModularAppStartupExceptionType.invalidRoutePath,
        message:
            'Nested route path "$path" of "$id" must be relative to its '
            'parent (full path "$fullPath").',
      );
    }
  }

  static void _checkParameters(String id, String fullPath) {
    final seen = <String>{};
    for (final segment in fullPath.split('/')) {
      if (segment.startsWith(':') && !seen.add(segment.substring(1))) {
        throw ModularAppStartupException(
          type: ModularAppStartupExceptionType.repeatedPathParameter,
          message:
              'Route path "$fullPath" of "$id" repeats the parameter '
              '"${segment.substring(1)}".',
        );
      }
    }
  }

  // `/accounts/:id` and `/accounts/:accountId` match the same locations.
  static String _shapeOf(String fullPath) => fullPath
      .split('/')
      .map((segment) => segment.startsWith(':') ? ':' : segment)
      .join('/');
}

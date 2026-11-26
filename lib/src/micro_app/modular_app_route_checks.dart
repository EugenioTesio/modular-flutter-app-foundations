/// @docImport 'modular_app_container.dart';
library;

import '../exceptions/modular_app_startup_exception.dart';
import '../routing/micro_app_route.dart';

/// Value that describes one declared route, looked up by its full path.
///
/// Holds the micro app that declared the route, or `null` for a host route,
/// and whether the route requires sign-in, its own flag or any ancestor's.
typedef ModularAppRouteFacts = ({
  String? microAppId,
  bool requiresAuthentication,
});

/// Startup checks on the host's and the micro apps' route trees, as static
/// helpers.
///
/// Use this through [ModularAppContainer.bootstrap]; it is not exported.
///
/// This is **not** a router mapping: it only reads the trees, and never
/// flattens, merges, or rewrites what the host or a micro app declared.
abstract final class ModularAppRouteChecks {
  /// Checks every route tree and returns the facts of each route, keyed by
  /// full path.
  ///
  /// Parameters:
  /// * [routesByMicroApp] - Each micro app's top-level route nodes, keyed by
  ///   micro app id.
  /// * [hostRoutes] - The host's own top-level route nodes, such as its
  ///   sign-in screen; defaults to none.
  ///
  /// A full path joins a route's path to its ancestors' paths, as go_router
  /// does: `/accounts` and `details/:accountId` give
  /// `/accounts/details/:accountId`. Paths directly in a
  /// [MicroAppRouteGroup] are absolute and start again.
  ///
  /// Throws a [ModularAppStartupException] naming the path and its owner
  /// when:
  /// * a micro app's top-level path, or a path directly in one of its
  ///   groups, doesn't start with `/<microAppId>`; a host's such path doesn't
  ///   start with `/`; or a nested path starts with `/`
  ///   ([ModularAppStartupExceptionType.invalidRoutePath]);
  /// * a full path repeats a parameter name
  ///   ([ModularAppStartupExceptionType.repeatedPathParameter]);
  /// * two routes share a full path, parameter names aside
  ///   ([ModularAppStartupExceptionType.duplicateRoutePath]);
  /// * a host route's full path is inside a micro app's namespace: its first
  ///   segment is a micro app id, or a parameter, which would match every
  ///   micro app's paths
  ///   ([ModularAppStartupExceptionType.reservedRoutePath]).
  static Map<String, ModularAppRouteFacts> check(
    Map<String, List<MicroAppRouteNode>> routesByMicroApp, {
    List<MicroAppRouteNode> hostRoutes = const [],
  }) {
    final facts = <String, ModularAppRouteFacts>{};
    // shape -> (full path, micro app id or null for the host)
    final owners = <String, (String, String?)>{};

    void record(String? id, String fullPath, bool requiresAuthentication) {
      final shape = _shapeOf(fullPath);
      final previous = owners[shape];
      if (previous != null) {
        final (path, owner) = previous;
        throw ModularAppStartupException(
          type: ModularAppStartupExceptionType.duplicateRoutePath,
          message:
              'Duplicate route path "$fullPath" declared by ${_label(id)}; '
              '${_label(owner)} already declares "$path".',
        );
      }
      owners[shape] = (fullPath, id);
      facts[fullPath] = (
        microAppId: id,
        requiresAuthentication: requiresAuthentication,
      );
    }

    _walk(
      hostRoutes,
      parentPath: null,
      parentRequiresAuthentication: false,
      visit: (route, fullPath, requiresAuthentication) {
        _checkForm(null, route.path, fullPath);
        _checkParameters(null, fullPath);
        _checkOutsideMicroApps(routesByMicroApp.keys, fullPath);
        record(null, fullPath, requiresAuthentication);
      },
    );
    for (final MapEntry(key: id, value: routes) in routesByMicroApp.entries) {
      _walk(
        routes,
        parentPath: null,
        parentRequiresAuthentication: false,
        visit: (route, fullPath, requiresAuthentication) {
          _checkForm(id, route.path, fullPath);
          _checkParameters(id, fullPath);
          record(id, fullPath, requiresAuthentication);
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

  /// Names a route's owner in a message: `"accounts"` or `the host`.
  static String _label(String? microAppId) =>
      microAppId == null ? 'the host' : '"$microAppId"';

  /// Checks the prefix rule for the micro app [id], or for the host when
  /// [id] is `null`. Only a top-level path, or a path directly in a group,
  /// has a full path equal to its own path: a nested path is always joined
  /// to its parent's.
  static void _checkForm(String? id, String path, String fullPath) {
    if (path == fullPath) {
      final prefix = id == null ? '/' : '/$id';
      final valid = id == null
          ? path.startsWith('/')
          : path == prefix || path.startsWith('$prefix/');
      if (!valid) {
        throw ModularAppStartupException(
          type: ModularAppStartupExceptionType.invalidRoutePath,
          message:
              'Top-level route path "$path" of ${_label(id)} must start '
              'with "$prefix".',
        );
      }
    } else if (path.startsWith('/')) {
      throw ModularAppStartupException(
        type: ModularAppStartupExceptionType.invalidRoutePath,
        message:
            'Nested route path "$path" of ${_label(id)} must be relative to '
            'its parent (full path "$fullPath").',
      );
    }
  }

  static void _checkParameters(String? id, String fullPath) {
    final seen = <String>{};
    for (final segment in fullPath.split('/')) {
      if (segment.startsWith(':') && !seen.add(segment.substring(1))) {
        throw ModularAppStartupException(
          type: ModularAppStartupExceptionType.repeatedPathParameter,
          message:
              'Route path "$fullPath" of ${_label(id)} repeats the parameter '
              '"${segment.substring(1)}".',
        );
      }
    }
  }

  /// Checks that the host route at [fullPath] stays out of every micro app's
  /// namespace. The router tries host routes first, so a host route there
  /// would hide the micro app's screens.
  static void _checkOutsideMicroApps(
    Iterable<String> microAppIds,
    String fullPath,
  ) {
    if (microAppIds.isEmpty) return;
    final first = fullPath.split('/').skip(1).firstOrNull ?? '';
    final owner = first.startsWith(':')
        ? microAppIds.first
        : microAppIds.where((id) => id == first).firstOrNull;
    if (owner == null) return;
    throw ModularAppStartupException(
      type: ModularAppStartupExceptionType.reservedRoutePath,
      message:
          'Host route path "$fullPath" is inside the namespace of "$owner" '
          '("/$owner"); host routes must stay outside every micro app\'s '
          'paths.',
    );
  }

  // `/accounts/:id` and `/accounts/:accountId` match the same locations.
  static String _shapeOf(String fullPath) => fullPath
      .split('/')
      .map((segment) => segment.startsWith(':') ? ':' : segment)
      .join('/');
}

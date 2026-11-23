// Reference implementation of the route-tree startup checks in
// contracts/routing.md ("Startup checks"). Dev-only: Core implements the same
// rules in its host sequence (step 4).
import 'package:flutter/foundation.dart';
import 'package:foundations/foundations.dart';

import 'reference_startup_exception.dart';

/// One declared route, with its full path and effective sign-in requirement.
@immutable
final class ReferenceRouteEntry {
  /// Creates an entry.
  const ReferenceRouteEntry({
    required this.fullPath,
    required this.route,
    required this.requiresAuthentication,
    required this.isTopLevel,
  });

  /// The route's path joined to its ancestors' paths, such as
  /// `/accounts/details/:accountId`.
  final String fullPath;

  /// The declaration.
  final MicroAppRoute route;

  /// Whether the route, or any ancestor route, requires sign-in.
  final bool requiresAuthentication;

  /// Whether the route is declared at the top level or directly in a group,
  /// where its path must be absolute.
  final bool isTopLevel;

  @override
  String toString() =>
      'ReferenceRouteEntry($fullPath, auth: $requiresAuthentication)';
}

/// The route-tree rules, as static helpers.
abstract final class ReferenceRouteValidation {
  /// Lists every route in [routes], depth first, with its full path and
  /// effective sign-in requirement. Performs no checks.
  static List<ReferenceRouteEntry> flatten(List<MicroAppRouteNode> routes) {
    final entries = <ReferenceRouteEntry>[];
    _walk(routes, parentPath: null, parentRequiresAuth: false, into: entries);
    return entries;
  }

  /// Checks every micro app's route tree, keyed by micro app id, and returns
  /// the flattened routes.
  ///
  /// Throws a [ReferenceStartupException] naming the path when:
  /// * a top-level path doesn't start with `/<microAppId>`;
  /// * a nested path starts with `/`;
  /// * a full path repeats a parameter name;
  /// * two routes share a full path (parameter names aside), naming both
  ///   micro apps.
  static List<ReferenceRouteEntry> validate(
    Map<String, List<MicroAppRouteNode>> routesByMicroAppId,
  ) {
    final all = <ReferenceRouteEntry>[];
    final owners = <String, (String, String)>{}; // shape -> (path, owner)
    for (final MapEntry(key: id, value: routes) in routesByMicroAppId.entries) {
      for (final entry in flatten(routes)) {
        _checkForm(id, entry);
        _checkParameters(id, entry);
        final shape = _shapeOf(entry.fullPath);
        final previous = owners[shape];
        if (previous != null) {
          final (path, owner) = previous;
          throw ReferenceStartupException(
            'Duplicate route path "${entry.fullPath}" declared by "$id"; '
            '"$owner" already declares "$path".',
          );
        }
        owners[shape] = (entry.fullPath, id);
        all.add(entry);
      }
    }
    return all;
  }

  /// Joins a parent's full path and a child's relative path.
  static String join(String parent, String child) =>
      parent.endsWith('/') ? '$parent$child' : '$parent/$child';

  static void _walk(
    List<MicroAppRouteNode> nodes, {
    required String? parentPath,
    required bool parentRequiresAuth,
    required List<ReferenceRouteEntry> into,
  }) {
    for (final node in nodes) {
      switch (node) {
        case MicroAppRoute():
          final fullPath = parentPath == null
              ? node.path
              : join(parentPath, node.path);
          final requiresAuth =
              parentRequiresAuth || node.requiresAuthentication;
          into.add(
            ReferenceRouteEntry(
              fullPath: fullPath,
              route: node,
              requiresAuthentication: requiresAuth,
              isTopLevel: parentPath == null,
            ),
          );
          _walk(
            node.routes,
            parentPath: fullPath,
            parentRequiresAuth: requiresAuth,
            into: into,
          );
        case MicroAppRouteGroup():
          // Grouped routes use absolute paths, so they restart the join.
          _walk(
            node.routes,
            parentPath: null,
            parentRequiresAuth: parentRequiresAuth,
            into: into,
          );
      }
    }
  }

  static void _checkForm(String id, ReferenceRouteEntry entry) {
    final path = entry.route.path;
    if (entry.isTopLevel) {
      if (path != '/$id' && !path.startsWith('/$id/')) {
        throw ReferenceStartupException(
          'Top-level route path "$path" of "$id" must start with "/$id".',
        );
      }
    } else if (path.startsWith('/')) {
      throw ReferenceStartupException(
        'Nested route path "$path" of "$id" must be relative to its parent '
        '(full path "${entry.fullPath}").',
      );
    }
  }

  static void _checkParameters(String id, ReferenceRouteEntry entry) {
    final seen = <String>{};
    for (final segment in entry.fullPath.split('/')) {
      if (segment.startsWith(':') && !seen.add(segment.substring(1))) {
        throw ReferenceStartupException(
          'Route path "${entry.fullPath}" of "$id" repeats the parameter '
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

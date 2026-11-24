import 'package:flutter/foundation.dart';
import 'package:foundations/foundations.dart';

/// One declared route, with its full path and effective sign-in requirement.
@immutable
final class ExampleRouteEntry {
  /// Creates an entry.
  ///
  /// Parameters:
  /// * [fullPath] - The route's path joined to its ancestors' paths.
  /// * [route] - The declaration.
  /// * [requiresAuthentication] - Whether the route or an ancestor requires
  ///   sign-in.
  /// * [isTopLevel] - Whether the route is top-level or directly in a group.
  const ExampleRouteEntry({
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

  /// Whether the route is top-level or directly in a group, where its path
  /// must be absolute.
  final bool isTopLevel;

  /// The full path with parameter names removed: `/a/:id` and `/a/:key`
  /// match the same locations, so they share the shape `/a/:`.
  String get shape =>
      '/${[for (final segment in Uri.parse(fullPath).pathSegments) segment.startsWith(':') ? ':' : segment].join('/')}';
}

/// The startup checks on the micro apps' route trees, as static helpers.
///
/// They only read the declarations; building the router is
/// `ExampleGoRoutes`' job.
abstract final class ExampleRouteHelper {
  /// Checks every micro app's route tree and returns the flattened routes.
  ///
  /// Parameters:
  /// * [routesByMicroAppId] - Each micro app's top-level route nodes, keyed
  ///   by micro app id.
  /// * [reservedPaths] - Paths the host keeps for itself, each with the
  ///   owner named in the error; defaults to none.
  ///
  /// Throws a [StateError] naming the path when:
  /// * a top-level path, or a path directly in a group, doesn't start with
  ///   `/<microAppId>`;
  /// * a nested path starts with `/`;
  /// * a full path repeats a parameter name;
  /// * two routes share a full path (parameter names aside), or a route
  ///   takes a reserved path, naming both owners.
  static List<ExampleRouteEntry> validate(
    Map<String, List<MicroAppRouteNode>> routesByMicroAppId, {
    Map<String, String> reservedPaths = const {},
  }) {
    final entries = <ExampleRouteEntry>[];
    // shape -> (path, owner)
    final owners = <String, (String, String)>{
      for (final MapEntry(key: path, value: owner) in reservedPaths.entries)
        path: (path, owner),
    };
    for (final MapEntry(key: id, value: routes) in routesByMicroAppId.entries) {
      for (final entry in flatten(routes)) {
        _checkPrefix(id, entry);
        _checkParameters(id, entry);
        final previous = owners[entry.shape];
        if (previous != null) {
          final (path, owner) = previous;
          throw StateError(
            'Duplicate route path "${entry.fullPath}" declared by "$id"; '
            '$owner already declares "$path".',
          );
        }
        owners[entry.shape] = (entry.fullPath, '"$id"');
        entries.add(entry);
      }
    }
    return entries;
  }

  /// Lists every route in [nodes] depth first, joining paths the way
  /// go_router does. Performs no checks.
  ///
  /// Parameters:
  /// * [nodes] - The route nodes to walk.
  /// * [parent] - Optional full path of the enclosing route; `null` at the
  ///   top level and directly in a group.
  /// * [parentRequiresAuthentication] - Whether an ancestor requires
  ///   sign-in; defaults to `false`.
  static Iterable<ExampleRouteEntry> flatten(
    Iterable<MicroAppRouteNode> nodes, {
    String? parent,
    bool parentRequiresAuthentication = false,
  }) sync* {
    for (final node in nodes) {
      switch (node) {
        case MicroAppRoute(:final path, :final routes):
          final fullPath = parent == null
              ? path
              : '${parent.endsWith('/') ? parent : '$parent/'}$path';
          final requiresAuthentication =
              parentRequiresAuthentication || node.requiresAuthentication;
          yield ExampleRouteEntry(
            fullPath: fullPath,
            route: node,
            requiresAuthentication: requiresAuthentication,
            isTopLevel: parent == null,
          );
          yield* flatten(
            routes,
            parent: fullPath,
            parentRequiresAuthentication: requiresAuthentication,
          );
        case MicroAppRouteGroup(:final routes):
          // Grouped routes use absolute paths, so they restart the join.
          yield* flatten(
            routes,
            parentRequiresAuthentication: parentRequiresAuthentication,
          );
      }
    }
  }

  /// Throws a [StateError] when a top-level path lacks the `/<id>` prefix or
  /// a nested path is absolute.
  static void _checkPrefix(String id, ExampleRouteEntry entry) {
    final path = entry.route.path;
    if (entry.isTopLevel && path != '/$id' && !path.startsWith('/$id/')) {
      throw StateError(
        'Top-level route path "$path" of "$id" must start with "/$id".',
      );
    }
    if (!entry.isTopLevel && path.startsWith('/')) {
      throw StateError(
        'Nested route path "$path" of "$id" must be relative to its parent '
        '(full path "${entry.fullPath}").',
      );
    }
  }

  /// Throws a [StateError] when the full path repeats a parameter name.
  static void _checkParameters(String id, ExampleRouteEntry entry) {
    final seen = <String>{};
    for (final segment in Uri.parse(entry.fullPath).pathSegments) {
      if (segment.startsWith(':') && !seen.add(segment.substring(1))) {
        throw StateError(
          'Route path "${entry.fullPath}" of "$id" repeats the parameter '
          '"${segment.substring(1)}".',
        );
      }
    }
  }
}

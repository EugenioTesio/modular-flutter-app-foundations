import 'package:flutter/widgets.dart';
import 'package:foundations/foundations.dart';
import 'package:go_router/go_router.dart';

import 'example_route_helper.dart';

/// The sign-in rule, as a go_router `redirect`: a route that requires
/// sign-in, directly or through an ancestor, redirects to [signInPath] while
/// [session] is [Unauthenticated].
///
/// Each route's effective requirement is worked out once, when the guard is
/// created, so [redirect] is a single lookup. go_router runs it on every
/// navigation, deep links included.
final class ExampleSignInGuard {
  /// Creates a guard over [routes].
  ///
  /// Parameters:
  /// * [session] - The session read on every navigation.
  /// * [signInPath] - The location a guarded route redirects to.
  /// * [routes] - The checked routes, with their effective requirements.
  ExampleSignInGuard({
    required this.session,
    required this.signInPath,
    required Iterable<ExampleRouteEntry> routes,
  }) : _requiresAuthentication = {
         for (final route in routes)
           route.fullPath: route.requiresAuthentication,
       };

  /// The session read on every navigation.
  final SessionContext session;

  /// Location a guarded route redirects to.
  final String signInPath;

  /// Full path pattern -> whether it requires sign-in.
  final Map<String, bool> _requiresAuthentication;

  /// Returns [signInPath] when the matched route requires sign-in and nobody
  /// is signed in, or `null` to let the navigation through.
  ///
  /// Parameters:
  /// * [context] - Unused; go_router's `redirect` signature requires it.
  /// * [state] - The navigation; [GoRouterState.fullPath] is the matched
  ///   route's full path pattern, such as `/accounts/details/:accountId`.
  String? redirect(BuildContext context, GoRouterState state) {
    final requiresAuthentication =
        _requiresAuthentication[state.fullPath] ?? false;
    return requiresAuthentication && session.current is Unauthenticated
        ? signInPath
        : null;
  }
}

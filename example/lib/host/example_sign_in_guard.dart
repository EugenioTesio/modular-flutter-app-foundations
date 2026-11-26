import 'package:flutter/widgets.dart';
import 'package:foundations/foundations.dart';
import 'package:go_router/go_router.dart';

/// The sign-in rule, as a go_router `redirect`: a route that requires
/// sign-in, directly or through an ancestor, redirects to [signInPath] while
/// [session] is [Unauthenticated].
///
/// The requirement comes from [ModularAppContainer.requiresAuthentication],
/// which worked it out from the micro apps' route trees at startup, so
/// [redirect] is a single lookup. go_router runs it on every navigation,
/// deep links included.
final class ExampleSignInGuard {
  /// Creates a guard.
  ///
  /// Parameters:
  /// * [session] - The session read on every navigation.
  /// * [signInPath] - The location a guarded route redirects to.
  /// * [requiresAuthentication] - Whether the route with a given full path
  ///   pattern requires sign-in; `null` for a route no micro app declares.
  const ExampleSignInGuard({
    required this.session,
    required this.signInPath,
    required this.requiresAuthentication,
  });

  /// The session read on every navigation.
  final SessionContext session;

  /// Location a guarded route redirects to.
  final String signInPath;

  /// Whether the route with a given full path pattern requires sign-in.
  final bool? Function(String fullPath) requiresAuthentication;

  /// Returns [signInPath] when the matched route requires sign-in and nobody
  /// is signed in, or `null` to let the navigation through.
  ///
  /// Parameters:
  /// * [context] - Unused; go_router's `redirect` signature requires it.
  /// * [state] - The navigation; [GoRouterState.fullPath] is the matched
  ///   route's full path pattern, such as `/accounts/details/:accountId`.
  String? redirect(BuildContext context, GoRouterState state) {
    final fullPath = state.fullPath;
    final guarded =
        fullPath != null && (requiresAuthentication(fullPath) ?? false);
    return guarded && session.current is Unauthenticated ? signInPath : null;
  }
}

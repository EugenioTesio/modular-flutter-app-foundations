/// @docImport '../capabilities/session_context.dart';
/// @docImport '../micro_app/micro_app.dart';
/// @docImport '../micro_app/modular_app_host.dart';
/// @docImport 'app_navigator.dart';
library;

import 'package:flutter/widgets.dart';

/// Function that builds the screen of a [MicroAppRoute].
///
/// Use this to turn a matched location into a widget. It receives:
///
/// * `parameters` - the path parameters (the `:name` segments) and the query
///   parameters, all as text and merged into one map. Their names never
///   overlap, so every route can be opened from a deep link.
/// * `body` - the extra values the caller passed to [AppNavigator.push],
///   [AppNavigator.go], or [AppNavigator.replace]. It is empty when the route
///   was opened from a deep link, so the screen must work, or recover,
///   without it.
///
/// This is **not** a router callback: it never sees router types, so Core
/// can change its router without any micro app changing.
///
/// Usage from a micro app:
/// ```dart
/// MicroAppRoute(
///   path: 'details/:accountId',
///   builder: (context, parameters, body) => AccountDetailsScreen(
///     accountId: parameters['accountId']!,
///     tab: parameters['tab'] ?? 'summary',
///     source: body['source'] as String?,
///   ),
/// )
/// ```
typedef MicroAppRouteBuilder = Widget Function(
  BuildContext context,
  Map<String, String> parameters,
  Map<String, Object> body,
);

/// Value that says how a [MicroAppRoute]'s screen is shown.
///
/// Use this to present a screen as a full-screen dialog, for example a form
/// the user completes or dismisses.
///
/// Built-in: Core maps each value to its router's page type.
enum RoutePresentation {
  /// A regular page, pushed with the platform's page transition.
  page,

  /// A full-screen dialog, which typically slides up and shows a close
  /// button instead of a back button.
  fullscreenDialog,
}

/// Node in a micro app's route tree.
///
/// Use this as the element type of [MicroApp.routes] and of the `routes` of
/// a [MicroAppRoute] or a [MicroAppRouteGroup]. It is `sealed`, so Core
/// matches its two variants exhaustively.
///
/// This is **not** a router route: Core builds the application's actual
/// router from these declarations.
///
/// Path rules:
/// * A route declared directly in [MicroApp.routes], or directly in a
///   [MicroAppRouteGroup], has an absolute path starting with
///   `/<microAppId>`, such as `/accounts`.
/// * A route declared in another route's `routes` has a path relative to its
///   parent, with no leading `/`, such as `details/:accountId`, which gives
///   the full path `/accounts/details/:accountId`.
/// * Every full path is unique in the application, and a full path never
///   repeats a parameter name. A duplicate stops startup.
/// * A full path that another micro app navigates to is part of the owning
///   micro app's public surface, like an endpoint address: changing it is a
///   breaking change for its callers.
/// * The host's own routes, in [ModularAppHost.routes], follow the
///   same rules, except that their absolute paths start with `/` and stay
///   outside every micro app's `/<microAppId>`.
///
/// Usage from a micro app:
/// ```dart
/// @override
/// List<MicroAppRouteNode> get routes => [
///   MicroAppRoute(
///     path: '/accounts',
///     builder: (context, parameters, body) => const AccountsScreen(),
///     routes: [
///       MicroAppRoute(
///         path: 'details/:accountId',
///         builder: (context, parameters, body) =>
///             AccountDetailsScreen(accountId: parameters['accountId']!),
///       ),
///     ],
///   ),
/// ];
/// ```
@immutable
sealed class MicroAppRouteNode {
  const MicroAppRouteNode();
}

/// Route that declares one screen of a micro app.
///
/// Use this for every screen a micro app owns. Navigation reaches it through
/// [AppNavigator] with a concrete location that matches its full path, and
/// a deep link reaches it the same way.
///
/// This is **not** a named route: routes have no name, and callers navigate
/// by location.
///
/// Built-in: Core turns it into a route of the application's router, merges
/// path and query parameters for the [builder], and redirects to sign-in
/// when the route requires it.
///
/// Rules:
/// * The route requires sign-in when it, or any ancestor route, sets
///   [requiresAuthentication]. It defaults to `true`, so routes are secure
///   unless they opt out.
/// * Path parameter names and query parameter names must not overlap.
///
/// Usage from a micro app:
/// ```dart
/// MicroAppRoute(
///   path: '/accounts/picker',
///   presentation: RoutePresentation.fullscreenDialog,
///   builder: (context, parameters, body) => AccountPickerScreen(
///     onPicked: (id) => navigator.pop(result: {'accountId': id}),
///   ),
/// )
/// ```
final class MicroAppRoute extends MicroAppRouteNode {
  /// Creates a route.
  ///
  /// Parameters:
  /// * [path] - The URL pattern, with `:name` segments for path parameters.
  ///   Absolute at the top level or directly in a group, relative inside
  ///   another route.
  /// * [builder] - Builds the screen.
  /// * [requiresAuthentication] - Whether the route requires sign-in;
  ///   defaults to `true`.
  /// * [presentation] - How the screen is shown; defaults to
  ///   [RoutePresentation.page].
  /// * [routes] - Optional child routes, with relative paths; defaults to
  ///   empty.
  const MicroAppRoute({
    required this.path,
    required this.builder,
    this.requiresAuthentication = true,
    this.presentation = RoutePresentation.page,
    this.routes = const [],
  });

  /// URL pattern of the route, such as `/accounts` or `details/:accountId`.
  final String path;

  /// Function that builds the route's screen.
  final MicroAppRouteBuilder builder;

  /// Whether the route requires sign-in.
  ///
  /// It also applies to every child route. While the session is
  /// [Unauthenticated], the host sends the user to sign in instead of
  /// showing the screen.
  final bool requiresAuthentication;

  /// Presentation of the route's screen.
  final RoutePresentation presentation;

  /// Child routes, whose paths are relative to [path].
  final List<MicroAppRouteNode> routes;

  @override
  String toString() => 'MicroAppRoute($path)';
}

/// Route group whose routes share a surrounding layout.
///
/// Use this for screens that sit inside a common layout that stays in place
/// while the user moves between them, such as a tab scaffold. The [builder]
/// may also wrap its child in a `StateScope.group(owns: [...])`, so state
/// shared by the group lives exactly as long as the user stays in it.
///
/// This is **not** a screen: it has no path of its own, and its routes use
/// absolute paths.
///
/// Built-in: Core turns it into a layout route of its router (for example a
/// go_router `ShellRoute`), so the layout is built once and kept while the
/// user moves between the group's routes.
///
/// Usage from a micro app:
/// ```dart
/// MicroAppRouteGroup(
///   builder: (context, child) => AccountsTabs(child: child),
///   routes: [
///     MicroAppRoute(
///       path: '/accounts/tabs/overview',
///       builder: (context, parameters, body) => const OverviewTab(),
///     ),
///     MicroAppRoute(
///       path: '/accounts/tabs/history',
///       builder: (context, parameters, body) => const HistoryTab(),
///     ),
///   ],
/// )
/// ```
final class MicroAppRouteGroup extends MicroAppRouteNode {
  /// Creates a route group.
  ///
  /// Parameters:
  /// * [builder] - Builds the shared layout around the current route's
  ///   screen.
  /// * [routes] - The grouped routes, with absolute paths.
  const MicroAppRouteGroup({required this.builder, required this.routes});

  /// Function that builds the shared layout around `child`, the screen of
  /// the current route in the group.
  final Widget Function(BuildContext context, Widget child) builder;

  /// Routes in the group, with absolute paths.
  final List<MicroAppRouteNode> routes;

  @override
  String toString() => 'MicroAppRouteGroup(${routes.length} routes)';
}

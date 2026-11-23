/// @docImport '../capabilities/session_context.dart';
/// @docImport '../inter_module/inter_module_value.dart';
library;

import 'package:flutter/foundation.dart';

import '../common/result.dart';
import '../exceptions/navigation_exception.dart';

/// Outcome of a screen opened with [AppNavigator.push] or
/// [AppNavigator.replace], once it closes.
///
/// Use this in a `switch` to tell a screen that returned a result
/// ([RouteCompleted]) from one the user left ([RouteCancelled]); the class
/// is `sealed`, so the switch is checked for exhaustiveness.
///
/// This is **not** a failure: navigation that could not start is an [Err]
/// holding a [NavigationException] instead.
@immutable
sealed class NavigationResult {
  const NavigationResult();
}

/// Outcome of a screen that closed with a [result].
final class RouteCompleted extends NavigationResult {
  /// Creates a completed outcome.
  ///
  /// Parameters:
  /// * [result] - The values the screen passed to [AppNavigator.pop].
  const RouteCompleted(this.result);

  /// Values the screen passed to [AppNavigator.pop], compared by content.
  ///
  /// When the screen belongs to another micro app, the values follow the
  /// payload rule (see [isInterModuleValue]) and match the result schema the
  /// owning micro app publishes for the route.
  final Map<String, Object> result;

  @override
  bool operator ==(Object other) =>
      other is RouteCompleted && mapEquals(other.result, result);

  @override
  int get hashCode => Object.hash(
    RouteCompleted,
    Object.hashAllUnordered(
      result.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
  );

  @override
  String toString() => 'RouteCompleted($result)';
}

/// Outcome of a screen that closed without a result.
///
/// Built-in: it is produced when the screen calls [AppNavigator.pop] without
/// a result, the user presses back, [AppNavigator.popUntil] closes the
/// screen, or a required sign-in is abandoned.
final class RouteCancelled extends NavigationResult {
  /// Creates a cancelled outcome.
  const RouteCancelled();

  @override
  bool operator ==(Object other) => other is RouteCancelled;

  @override
  int get hashCode => (RouteCancelled).hashCode;

  @override
  String toString() => 'RouteCancelled()';
}

/// Contract that navigates between the application's screens by location.
///
/// Use this to open any screen, including another micro app's, without
/// importing that micro app or a router package. A `path` is a concrete
/// location such as `/accounts/details/a1?tab=history`: path parameters are
/// already filled in and query parameters are part of it, so the same
/// location also works as a deep link. A path another micro app navigates to
/// is part of the owning micro app's public surface, like an endpoint
/// address.
///
/// A `body` carries extra values to the destination screen. A deep link has
/// no body, so a screen must still work, or recover, without one. When the
/// destination belongs to another micro app, body values follow the payload
/// rule (see [isInterModuleValue]), so the caller imports none of that micro
/// app's types.
///
/// This is **not** a router: micro apps declare routes, and Core builds the
/// actual router from them. Navigation never throws: a location that matches
/// no declared route gives an [Err] holding a [RouteNotFoundException].
///
/// Built-in: Core implements it on top of the application's router and gives
/// it to each micro app through its context.
///
/// Usage from a micro app:
/// ```dart
/// // Transfers opens the Accounts picker and waits for the choice.
/// switch (await navigator.push(
///   '/accounts/picker',
///   body: {'purpose': 'transfer_source'},
/// )) {
///   case Ok(value: RouteCompleted(:final result)):
///     selectSource(result['accountId']! as String);
///   case Ok(value: RouteCancelled()):
///     break;
///   case Err(:final failure):
///     logger.warning('Picker unavailable', error: failure);
/// }
///
/// // The picker returns the choice.
/// navigator.pop(result: {'accountId': account.id});
/// ```
abstract interface class AppNavigator {
  /// Opens a screen on top of the current one and waits for it to close.
  ///
  /// Parameters:
  /// * [path] - The location to open, such as `/accounts/details/a1`.
  /// * [body] - Optional extra values for the screen; defaults to empty.
  ///
  /// Completes when that screen closes, with an [Ok] holding
  /// [RouteCompleted] when it returned a result or [RouteCancelled] when it
  /// did not. When the route requires sign-in while the session is
  /// [Unauthenticated], the user is sent to sign in first; abandoning sign-in
  /// completes with [RouteCancelled]. Completes immediately with an [Err]
  /// holding a [RouteNotFoundException] when [path] matches no route.
  Future<Result<NavigationResult, NavigationException>> push(
    String path, {
    Map<String, Object> body = const {},
  });

  /// Goes to a screen, replacing the whole stack.
  ///
  /// Use it for "back to home after a transfer" or switching tabs.
  ///
  /// Parameters:
  /// * [path] - The location to go to.
  /// * [body] - Optional extra values for the screen; defaults to empty.
  ///
  /// Returns an [Ok] when navigation started, or an [Err] holding a
  /// [RouteNotFoundException] when [path] matches no route.
  Result<void, NavigationException> go(
    String path, {
    Map<String, Object> body = const {},
  });

  /// Replaces the current screen and waits for the new one to close.
  ///
  /// Use it for steps that should not be returned to, such as a confirmation
  /// after a form.
  ///
  /// Parameters:
  /// * [path] - The location that replaces the current screen.
  /// * [body] - Optional extra values for the screen; defaults to empty.
  ///
  /// Completes the same way as [push].
  Future<Result<NavigationResult, NavigationException>> replace(
    String path, {
    Map<String, Object> body = const {},
  });

  /// Closes the current screen.
  ///
  /// Parameters:
  /// * [result] - Optional values for the screen's opener. A non-null result
  ///   completes the opener with a [RouteCompleted] holding it; `null`
  ///   completes it with [RouteCancelled].
  void pop({Map<String, Object>? result});

  /// Closes screens until the one at a location is on top.
  ///
  /// Parameters:
  /// * [path] - The location of the screen to return to.
  ///
  /// Each closed screen's opener completes with [RouteCancelled]. When no
  /// screen in the stack is at [path], closes nothing and returns an [Err]
  /// holding a [RouteNotFoundException].
  Result<void, NavigationException> popUntil(String path);
}

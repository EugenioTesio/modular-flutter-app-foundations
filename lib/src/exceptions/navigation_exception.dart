/// @docImport '../common/result.dart';
/// @docImport '../routing/app_navigator.dart';
library;

import 'package:flutter/foundation.dart';

/// Exception that explains why navigation could not start.
///
/// Use this to react when [AppNavigator] returns an [Err]. It is `sealed`, so
/// a `switch` over it is checked for exhaustiveness; its only variant today is
/// [RouteNotFoundException].
///
/// This is **not** thrown: the navigator returns it inside an [Err]. Its
/// variants live in this file because Dart requires a sealed class's subtypes
/// in the same library.
@immutable
sealed class NavigationException implements Exception {
  const NavigationException();
}

/// Exception returned when no route matches the requested [path].
///
/// Use this to detect a location that no micro app declares, for example
/// after a micro app removed a screen.
///
/// Built-in: [AppNavigator.push], [AppNavigator.go], and
/// [AppNavigator.replace] return it when the location matches no declared
/// route, and [AppNavigator.popUntil] returns it when no screen in the stack
/// is at [path].
///
/// Usage from a micro app:
/// ```dart
/// switch (await navigator.push('/statements/a1')) {
///   case Err(failure: RouteNotFoundException(:final path)):
///     logger.warning('No screen at $path');
///   case Ok(:final value):
///     handle(value);
/// }
/// ```
final class RouteNotFoundException extends NavigationException {
  /// Creates a route-not-found exception.
  ///
  /// Parameters:
  /// * [path] - The location that was requested.
  const RouteNotFoundException(this.path);

  /// Location that was requested, such as `/accounts/details/a1`.
  final String path;

  @override
  bool operator ==(Object other) =>
      other is RouteNotFoundException && other.path == path;

  @override
  int get hashCode => Object.hash(RouteNotFoundException, path);

  @override
  String toString() => 'RouteNotFoundException($path)';
}

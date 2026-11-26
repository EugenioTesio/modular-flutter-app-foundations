/// @docImport 'app_logger.dart';
/// @docImport 'crash_reporter.dart';
library;

/// Contract that records product analytics for the application.
///
/// Use this to log the screens users see and the actions they take. Event and
/// screen names follow `<microAppId>.<name>`, and property values are
/// [String], [num], or [bool] that never contain personal data.
///
/// This is **not** for diagnostics: use [AppLogger] for logs and
/// [CrashReporter] for errors.
///
/// Built-in: Core implements it on top of whichever analytics vendor the host
/// uses, so replacing the vendor changes no micro app. Standalone examples
/// and tests may use a no-op implementation; the feature behaves the same
/// apart from the missing side effects.
///
/// Usage from a micro app:
/// ```dart
/// await analytics.logScreenView('accounts.overview');
/// await analytics.logEvent(
///   'accounts.transfer_started',
///   properties: {'fromSavings': true, 'step': 1},
/// );
/// ```
abstract interface class Analytics {
  /// Records a named event.
  ///
  /// Parameters:
  /// * [name] - The event name, such as `accounts.overview_loaded`.
  /// * [properties] - Optional values that describe the event; defaults to
  ///   empty.
  ///
  /// Never fails toward the caller: a vendor failure is handled inside the
  /// implementation.
  Future<void> logEvent(
    String name, {
    Map<String, Object> properties = const {},
  });

  /// Records that a screen was shown.
  ///
  /// Parameters:
  /// * [screenName] - The screen name, such as `accounts.overview`.
  /// * [properties] - Optional values that describe the view; defaults to
  ///   empty.
  ///
  /// Never fails toward the caller.
  Future<void> logScreenView(
    String screenName, {
    Map<String, Object> properties = const {},
  });
}

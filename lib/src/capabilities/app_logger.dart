/// @docImport 'analytics.dart';
/// @docImport 'crash_reporter.dart';
library;

/// Severity of a log entry, ordered from lowest to highest.
enum LogLevel {
  /// Detail useful only while developing.
  debug,

  /// Normal, noteworthy event.
  info,

  /// Something unexpected that the application recovered from.
  warning,

  /// Failure the user may notice.
  error,
}

/// Contract that writes diagnostic logs for the application.
///
/// Use this to leave a trail that helps diagnose a problem, through the
/// [AppLoggerShortcuts] methods. Log identifiers and counts, never
/// credentials or personal data such as an email address or a phone number.
///
/// This is **not** for product analytics or error reporting: use [Analytics]
/// and [CrashReporter] for those.
///
/// Built-in: Core implements it, for example by writing to the console in
/// development and to a log service in production. Standalone examples may
/// use a console or no-op implementation; the feature behaves the same either
/// way.
///
/// Usage from a micro app:
/// ```dart
/// logger.info('Accounts loaded', context: {'count': accounts.length});
/// logger.error('Transfer failed', error: exception, stackTrace: stackTrace);
/// ```
abstract interface class AppLogger {
  /// Writes one log entry.
  ///
  /// Parameters:
  /// * [level] - The severity of the entry.
  /// * [message] - What happened, in plain words.
  /// * [error] - Optional error that caused the entry.
  /// * [stackTrace] - Optional stack trace of [error].
  /// * [context] - Optional structured values; defaults to empty.
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object> context = const {},
  });
}

/// Shortcuts that write an [AppLogger] entry at a fixed [LogLevel].
///
/// Built-in: each forwards to [AppLogger.log], so fakes only need to
/// implement [AppLogger.log].
extension AppLoggerShortcuts on AppLogger {
  /// Writes a [LogLevel.debug] entry.
  ///
  /// Parameters:
  /// * [message] - What happened, in plain words.
  /// * [context] - Optional structured values; defaults to empty.
  void debug(String message, {Map<String, Object> context = const {}}) =>
      log(LogLevel.debug, message, context: context);

  /// Writes a [LogLevel.info] entry.
  ///
  /// Parameters:
  /// * [message] - What happened, in plain words.
  /// * [context] - Optional structured values; defaults to empty.
  void info(String message, {Map<String, Object> context = const {}}) =>
      log(LogLevel.info, message, context: context);

  /// Writes a [LogLevel.warning] entry.
  ///
  /// Parameters:
  /// * [message] - What happened, in plain words.
  /// * [error] - Optional error the application recovered from.
  /// * [stackTrace] - Optional stack trace of [error].
  /// * [context] - Optional structured values; defaults to empty.
  void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object> context = const {},
  }) => log(
    LogLevel.warning,
    message,
    error: error,
    stackTrace: stackTrace,
    context: context,
  );

  /// Writes a [LogLevel.error] entry.
  ///
  /// Parameters:
  /// * [message] - What happened, in plain words.
  /// * [error] - Optional error that caused the failure.
  /// * [stackTrace] - Optional stack trace of [error].
  /// * [context] - Optional structured values; defaults to empty.
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object> context = const {},
  }) => log(
    LogLevel.error,
    message,
    error: error,
    stackTrace: stackTrace,
    context: context,
  );
}

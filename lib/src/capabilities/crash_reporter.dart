/// @docImport '../common/result.dart';
/// @docImport 'session_context.dart';
library;

/// Contract that reports crashes and handled errors for the application.
///
/// Use this for errors the user may notice or that point to a bug, such as an
/// unexpected exception while parsing a file.
///
/// This is **not** for expected outcomes: an [Err] from the API client is a
/// normal result, so report it only when it is truly unexpected.
///
/// Built-in: Core implements it on top of the host's crash-reporting vendor.
/// Standalone examples and tests may use a no-op implementation.
///
/// Usage from a micro app:
/// ```dart
/// try {
///   await importStatement(file);
/// } on FormatException catch (error, stackTrace) {
///   await crashReporter.recordError(
///     error,
///     stackTrace,
///     reason: 'Statement import failed',
///     context: {'fileType': 'csv'},
///   );
/// }
/// ```
abstract interface class CrashReporter {
  /// Reports a handled error.
  ///
  /// Parameters:
  /// * [error] - The error or exception that was caught.
  /// * [stackTrace] - Optional stack trace of the error.
  /// * [reason] - Optional short, human-readable explanation.
  /// * [context] - Optional values that help diagnose the error; defaults to
  ///   empty.
  ///
  /// Neither [reason] nor [context] may contain credentials or personal data.
  /// Never fails toward the caller.
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, Object> context = const {},
  });

  /// Associates later reports with a pseudonymous user identifier.
  ///
  /// Parameters:
  /// * [pseudonymousId] - Optional identifier, such as
  ///   [UserIdentity.userId]; `null` clears the association. Never an email
  ///   address, a name, a phone number, or any other personal data.
  Future<void> setUserIdentifier(String? pseudonymousId);
}

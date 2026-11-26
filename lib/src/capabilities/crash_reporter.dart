/// @docImport '../common/result.dart';
/// @docImport '../micro_app/micro_app.dart';
/// @docImport 'session_context.dart';
library;

/// Contract that reports handled errors for the application.
///
/// Use this for errors the user may notice or that point to a bug, such as an
/// unexpected exception while parsing a file.
///
/// This is **not** for expected outcomes: an [Err] from the API client is a
/// normal result, so report it only when it is truly unexpected. Nor is it for
/// crashes, uncaught errors, or "application not responding" freezes: the
/// application captures those without any call from a micro app.
///
/// Built-in: Core implements it on top of the host's crash-reporting vendor,
/// and also captures crashes, uncaught errors, and freezes. It gives each
/// micro app its own reporter, which adds the [MicroApp.id] to every report as
/// `microAppId`, and it sets the user identifier as the session changes.
/// Standalone examples and tests may use a no-op implementation.
///
/// Rules:
/// * A report leaves the device, so no part of it may contain credentials or
///   personal data: not the reason, not the context, and not the error, whose
///   message is sent too.
/// * Some errors quote their input. A [FormatException] prints the text it
///   could not parse, so report a copy that keeps only its message.
///
/// Usage from a micro app:
/// ```dart
/// try {
///   await importStatement(file);
/// } on FormatException catch (error, stackTrace) {
///   // Reporting `error` itself would send the text it could not read.
///   await crashReporter.recordError(
///     FormatException(error.message),
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
  /// * [error] - The error or exception that was caught. Its message is sent
  ///   with the report.
  /// * [stackTrace] - Optional stack trace of the error; `null` when there is
  ///   none, as for the failure inside an [Err].
  /// * [reason] - Optional short, human-readable explanation.
  /// * [context] - Optional values that help diagnose this error, each a
  ///   [String], [num], or [bool]; defaults to empty. Later reports don't
  ///   carry them.
  ///
  /// No parameter may contain credentials or personal data. Never fails toward
  /// the caller.
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, Object> context = const {},
  });

  /// Associates later reports with a pseudonymous user identifier.
  ///
  /// Micro apps never call this: the identifier applies to the whole
  /// application, so Core sets and clears it as the session changes.
  ///
  /// Parameters:
  /// * [pseudonymousId] - Optional identifier, such as
  ///   [UserIdentity.userId]; `null` clears the association. Never an email
  ///   address, a name, a phone number, or any other personal data.
  ///
  /// Never fails toward the caller.
  Future<void> setUserIdentifier(String? pseudonymousId);
}

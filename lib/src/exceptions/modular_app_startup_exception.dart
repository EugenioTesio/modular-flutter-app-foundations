/// @docImport '../common/result.dart';
/// @docImport '../micro_app/micro_app.dart';
/// @docImport '../micro_app/modular_app_container.dart';
/// @docImport '../micro_app/modular_app_host.dart';
/// @docImport '../routing/micro_app_route.dart';
/// @docImport 'duplicate_endpoint_exception.dart';
library;

/// Classification of a [ModularAppStartupException].
enum ModularAppStartupExceptionType {
  /// Two micro apps share a [MicroApp.id].
  duplicateMicroAppId,

  /// Two micro apps, or the host and a micro app, declare the same key in
  /// [MicroApp.storedKeys] or [ModularAppHost.storedKeys].
  duplicateStoredKey,

  /// A route path breaks the prefix rule: a micro app's top-level path, or a
  /// path directly in a [MicroAppRouteGroup], doesn't start with
  /// `/<microAppId>`, a host's such path doesn't start with `/`, or a nested
  /// path starts with `/`.
  invalidRoutePath,

  /// Two routes share a full path, parameter names aside.
  duplicateRoutePath,

  /// A full path uses the same parameter name twice, such as
  /// `/accounts/:id/cards/:id`.
  repeatedPathParameter,

  /// A route in [ModularAppHost.routes] takes a path inside a micro app's
  /// namespace: `/<microAppId>` or anything under it.
  reservedRoutePath,

  /// [ModularAppContainer.bootstrap] was called a second time.
  alreadyBootstrapped,
}

/// Exception thrown when [ModularAppContainer.bootstrap] finds a wiring
/// mistake and startup must stop.
///
/// Use this to tell a broken set of micro apps (two sharing an id or a
/// stored key, or a route path that breaks a rule) from a failure inside a
/// micro app's own [MicroApp.initialize], which propagates unchanged.
///
/// This is **not** returned in an [Err] like most Foundations exceptions: it
/// is thrown, like [DuplicateEndpointException], because nothing can recover
/// from it at runtime. Fix the declarations instead.
///
/// Built-in: [ModularAppContainer.bootstrap] throws it before any micro app
/// initializes for a duplicate id or stored key, and after initialization
/// for a broken route tree.
///
/// The [message] names every culprit (the value, and each micro app that
/// declares it), and never holds payloads, credentials, or personal data.
///
/// Usage from a host:
/// ```dart
/// try {
///   await container.bootstrap(
///     communication: communication,
///     contextFor: contextFor,
///   );
/// } on ModularAppStartupException catch (exception) {
///   logger.error('Startup stopped', error: exception);
///   rethrow;
/// }
/// ```
final class ModularAppStartupException implements Exception {
  /// Creates a startup exception.
  ///
  /// Parameters:
  /// * [type] - The rule that was broken.
  /// * [message] - What went wrong, naming every culprit.
  const ModularAppStartupException({required this.type, required this.message});

  /// Rule that was broken.
  final ModularAppStartupExceptionType type;

  /// Description that names every culprit, such as the stored key and both
  /// micro apps that declare it.
  final String message;

  @override
  String toString() => 'ModularAppStartupException(${type.name}): $message';
}

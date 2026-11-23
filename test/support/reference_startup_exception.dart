// The failure the reference host and route validation raise when startup must
// stop. Dev-only: Core defines its own startup failure, using this as the
// reference for what each message must name.

/// Exception thrown when the host sequence finds a wiring mistake (a
/// duplicate micro app id, stored key, or route path, or a badly formed
/// path) and startup stops.
final class ReferenceStartupException implements Exception {
  /// Creates a startup exception.
  ///
  /// Parameters:
  /// * [message] - What went wrong, naming every culprit.
  const ReferenceStartupException(this.message);

  /// Description that names the culprits, such as the key and both micro
  /// apps.
  final String message;

  @override
  String toString() => 'ReferenceStartupException: $message';
}

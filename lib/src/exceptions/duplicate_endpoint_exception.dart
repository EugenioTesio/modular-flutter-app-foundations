import '../inter_module/inter_module_communication.dart';

/// Thrown when an address is registered twice for the same [type].
///
/// It signals a wiring mistake, not a runtime outcome, so hosts let it stop
/// startup.
final class DuplicateEndpointException implements Exception {
  /// Creates the exception for [url] and [type].
  const DuplicateEndpointException({required this.url, required this.type});

  /// The address that was registered twice.
  final String url;

  /// The registry (data or UI) in which the duplicate happened.
  final EndpointType type;

  @override
  String toString() =>
      'DuplicateEndpointException: "$url" is already registered as a '
      '${type.name} endpoint.';
}

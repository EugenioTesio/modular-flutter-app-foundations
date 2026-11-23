/// @docImport '../common/result.dart';
/// @docImport '../inter_module/endpoint_provider.dart';
library;

import '../inter_module/inter_module_communication.dart';

/// Exception thrown when an address is registered twice for the same [type].
///
/// Use this to stop startup: it signals a wiring mistake, such as two micro
/// apps declaring the same address, not a runtime outcome.
///
/// This is **not** returned in an [Err] like the other Foundations
/// exceptions: it is thrown, because nothing can recover from it at runtime.
///
/// Built-in: [InterModuleCommunication.register] and
/// [InterModuleCommunication.registerWidget] throw it, and so does
/// [InterModuleProviderRegistration.registerProviders], which calls them.
final class DuplicateEndpointException implements Exception {
  /// Creates a duplicate-endpoint exception.
  ///
  /// Parameters:
  /// * [url] - The address that was registered twice.
  /// * [type] - The registry, data or UI, in which the duplicate happened.
  const DuplicateEndpointException({required this.url, required this.type});

  /// Address that was registered twice, such as `/accounts/v1/details`.
  final String url;

  /// Registry, data or UI, in which the duplicate happened.
  final EndpointType type;

  @override
  String toString() =>
      'DuplicateEndpointException: "$url" is already registered as a '
      '${type.name} endpoint.';
}

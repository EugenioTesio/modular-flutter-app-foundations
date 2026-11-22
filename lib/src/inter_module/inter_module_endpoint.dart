import 'package:flutter/foundation.dart';

/// Describes one inter-module call: where it goes, what it sends, and — when
/// a provider registers it — which parameters are required.
///
/// The [url] is an in-process registry key. By convention it names the owning
/// module and a version: `/<module>/v<N>/<name>`, for example
/// `/module-b/v1/details`. An incompatible change is published under a new
/// version while the old one keeps serving existing consumers.
@immutable
final class InterModuleEndpoint {
  /// Creates an endpoint description.
  const InterModuleEndpoint({
    required this.url,
    this.parameters = const {},
    this.requiredParameters = const {},
    this.traceName,
  });

  /// The in-process address, such as `/module-b/v1/details`.
  final String url;

  /// The call parameters.
  ///
  /// Values follow the payload rule (see `isInterModuleValue`). Parameters the
  /// provider did not declare are passed to it unchanged.
  final Map<String, Object?> parameters;

  /// The parameter names the provider requires.
  ///
  /// Only read on the endpoint a provider registers. On a consumer's call it
  /// is ignored: validation always uses the provider's declaration.
  final Set<String> requiredParameters;

  /// An optional name for timing this call, such as `module_a.details`.
  ///
  /// Only read on a consumer's call. The communication implementation records
  /// the call's name, duration, and status in its own diagnostics. It is a
  /// hint, not a capability.
  final String? traceName;

  @override
  bool operator ==(Object other) =>
      other is InterModuleEndpoint &&
      other.url == url &&
      mapEquals(other.parameters, parameters) &&
      setEquals(other.requiredParameters, requiredParameters) &&
      other.traceName == traceName;

  @override
  int get hashCode => Object.hash(
    url,
    Object.hashAllUnordered(
      parameters.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
    Object.hashAllUnordered(requiredParameters),
    traceName,
  );

  @override
  String toString() =>
      'InterModuleEndpoint($url, parameters: $parameters, '
      'requiredParameters: $requiredParameters, traceName: $traceName)';
}

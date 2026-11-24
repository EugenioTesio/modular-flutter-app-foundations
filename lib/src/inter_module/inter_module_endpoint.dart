/// @docImport 'endpoint_provider.dart';
/// @docImport 'inter_module_communication.dart';
/// @docImport 'inter_module_validator.dart';
library;

import 'package:flutter/foundation.dart';

/// Value that describes one inter-module call: where it goes, what it sends,
/// and, when a provider registers it, which parameters are required.
///
/// Use this in two roles:
///
/// * A provider returns it from [DataEndpointProvider.endpoint] or
///   [WidgetEndpointProvider.endpoint] to declare its [url] and
///   [requiredParameters].
/// * A consumer passes it to [InterModuleCommunication.request] or
///   [InterModuleCommunication.getWidget] with the [parameters] to send and,
///   optionally, a [traceName].
///
/// This is **not** a network address: [url] is a key in Core's in-process
/// registry, and no HTTP call is made.
///
/// Usage from a provider and a consumer:
/// ```dart
/// // Declared by the Accounts micro app.
/// const detailsEndpoint = InterModuleEndpoint(
///   url: '/accounts/v1/details',
///   requiredParameters: {'id'},
/// );
///
/// // Called by the Transfers micro app.
/// final response = await communication.request(
///   endpoint: const InterModuleEndpoint(
///     url: '/accounts/v1/details',
///     parameters: {'id': 'a1'},
///     traceName: 'transfers.account_details',
///   ),
/// );
/// ```
@immutable
final class InterModuleEndpoint {
  /// Creates an endpoint description.
  ///
  /// Parameters:
  /// * [url] - The in-process address, such as `/accounts/v1/details`.
  /// * [parameters] - Optional values to send on a call; defaults to empty.
  /// * [requiredParameters] - Optional names the provider requires; defaults
  ///   to empty. Only read at registration.
  /// * [traceName] - Optional name for timing a call; only read on calls.
  const InterModuleEndpoint({
    required this.url,
    this.parameters = const {},
    this.requiredParameters = const {},
    this.traceName,
  });

  /// In-process address of the endpoint, such as `/accounts/v1/details`.
  ///
  /// By convention it names the owning micro app and a version,
  /// `/<microAppId>/v<N>/<name>`. An incompatible change to the parameters or
  /// the result is published under a new version, while the old one keeps
  /// serving existing consumers.
  final String url;

  /// Parameters sent with a call.
  ///
  /// Values follow the payload rule (see
  /// [InterModuleValidator.isValidPayload]). Parameters the provider did not
  /// declare reach it unchanged. Only read on a consumer's call.
  final Map<String, Object?> parameters;

  /// Names of the parameters the provider requires.
  ///
  /// Only read on the endpoint a provider registers. On a consumer's call it
  /// is ignored, because validation always uses the provider's declaration. A
  /// required parameter that is absent or `null` stops the call before the
  /// provider runs; an empty string counts as present.
  final Set<String> requiredParameters;

  /// Optional name for timing this call, such as
  /// `transfers.account_details`.
  ///
  /// Only read on a consumer's call. The communication implementation records
  /// the name, the call's duration, and its status in its own diagnostics. It
  /// is a hint, not a capability, and follows `<microAppId>.<name>`.
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

  /// Returns a description with the address, the parameter names, and the
  /// trace name, but no parameter values, so printing an endpoint never
  /// leaks personal data.
  @override
  String toString() =>
      'InterModuleEndpoint($url, parameters: ${parameters.keys.toList()}, '
      'requiredParameters: $requiredParameters, traceName: $traceName)';
}

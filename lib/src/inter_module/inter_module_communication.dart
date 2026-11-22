import 'package:flutter/widgets.dart';

import 'inter_module_endpoint.dart';
import 'inter_module_response.dart';

/// Answers a data endpoint asynchronously.
///
/// It is invoked only after the required-parameter check passes. If it
/// throws, or its future completes with an error, the caller gets a 500.
typedef InterModuleHandler =
    Future<InterModuleCommunicationResponse<Map<String, Object?>>> Function(
      Map<String, Object?> parameters,
    );

/// Answers a UI endpoint synchronously with a ready-to-place element.
///
/// It returns the element without waiting for that element's own data. If it
/// throws, the caller gets a 500.
typedef InterModuleWidgetFactory =
    InterModuleCommunicationResponse<Widget> Function(
      Map<String, Object?> parameters,
    );

/// The two types of endpoint. Each type has its own registry, so the same
/// address can be registered once as data and once as UI.
enum EndpointType {
  /// Answered by an [InterModuleHandler].
  data,

  /// Answered by an [InterModuleWidgetFactory].
  widget,
}

/// Connects isolated micro apps through explicit, versioned endpoints.
///
/// Core implements it, and hosts give it to micro apps through their
/// context. There is no global instance. Every implementation must behave as
/// listed below; `package:foundations/testing.dart` verifies it.
///
/// * An address not registered for the type → 404 `endpoint_not_registered`.
/// * A provider-declared required parameter that is absent or null → 400
///   `missing_required_parameters`, and the provider is not called. An empty
///   string counts as present and reaches the provider.
/// * Only the provider's declared required parameters count; the consumer's
///   are ignored. Extra parameters reach the provider unchanged.
/// * The provider's response reaches the consumer unchanged.
/// * A provider that throws, or whose future fails → 500, with no data and no
///   exception details.
/// * Registering an address twice for the same type throws a
///   `DuplicateEndpointException`.
/// * [getWidget] returns synchronously, with the exact element the factory
///   built.
/// * [isRegistered] never invokes a provider.
/// * A call whose endpoint has a `traceName` is timed, and its name,
///   duration, and status are recorded in the implementation's diagnostics.
///
/// Micro apps never call [register] or [registerWidget] directly: they
/// declare endpoint providers, and the host registers them all at once after
/// every micro app has initialized.
abstract interface class InterModuleCommunication {
  /// Registers a data endpoint at `endpoint.url`, with the required
  /// parameters in `endpoint.requiredParameters`.
  ///
  /// Throws a `DuplicateEndpointException` if the address is already registered
  /// as a data endpoint.
  void register({
    required InterModuleEndpoint endpoint,
    required InterModuleHandler handler,
  });

  /// Requests data from the endpoint at `endpoint.url`, with
  /// `endpoint.parameters`.
  Future<InterModuleCommunicationResponse<Map<String, Object?>>> request({
    required InterModuleEndpoint endpoint,
  });

  /// Registers a UI endpoint at `endpoint.url`, with the required parameters
  /// in `endpoint.requiredParameters`.
  ///
  /// Throws a `DuplicateEndpointException` if the address is already registered
  /// as a UI endpoint.
  void registerWidget({
    required InterModuleEndpoint endpoint,
    required InterModuleWidgetFactory factory,
  });

  /// Gets a UI element from the endpoint at `endpoint.url`, synchronously.
  ///
  /// Loading and error states after the element is returned belong to the
  /// module that provides it.
  InterModuleCommunicationResponse<Widget> getWidget({
    required InterModuleEndpoint endpoint,
  });

  /// Whether [url] is registered for [type]. Never invokes a provider.
  bool isRegistered({required String url, required EndpointType type});
}

/// @docImport '../exceptions/duplicate_endpoint_exception.dart';
/// @docImport 'endpoint_provider.dart';
/// @docImport 'inter_module_status.dart';
library;

import 'package:flutter/widgets.dart';

import 'inter_module_endpoint.dart';
import 'inter_module_response.dart';

/// Function that answers a data endpoint asynchronously.
///
/// It is invoked only after every required parameter is present and not
/// `null`. If it throws, or its future completes with an error, the caller
/// receives [InterModuleStatusCode.internalError].
///
/// This is **not** written by micro apps directly: they implement
/// [DataEndpointProvider.handle], which the host registers as the handler.
typedef InterModuleHandler =
    Future<InterModuleCommunicationResponse<Map<String, Object?>>> Function(
      Map<String, Object?> parameters,
    );

/// Function that answers a UI endpoint synchronously with a ready-to-place
/// widget.
///
/// It returns the widget without waiting for the widget's own data. If it
/// throws, the caller receives [InterModuleStatusCode.internalError].
///
/// This is **not** written by micro apps directly: they implement
/// [WidgetEndpointProvider.build], which the host registers as the factory.
typedef InterModuleWidgetFactory =
    InterModuleCommunicationResponse<Widget> Function(
      Map<String, Object?> parameters,
    );

/// Type of an endpoint: data or UI.
///
/// Each type has its own registry, so the same address can be registered once
/// as data and once as UI.
enum EndpointType {
  /// Endpoint answered by an [InterModuleHandler].
  data,

  /// Endpoint answered by an [InterModuleWidgetFactory].
  widget,
}

/// Contract that connects isolated micro apps through explicit, versioned
/// endpoints.
///
/// Use this when your micro app needs data or UI that another micro app
/// owns: call [request] or [getWidget] with the other micro app's endpoint
/// address. To offer your own endpoints, declare a [DataEndpointProvider] or
/// [WidgetEndpointProvider] instead.
///
/// This is **not** a network client: calls stay inside the app process, and
/// the addresses are registry keys, not URLs on a server.
///
/// Built-in: Core implements it and gives each micro app the same instance
/// through its context; there is no global instance. Every implementation
/// behaves as follows, and the conformance check in
/// `package:foundations/testing.dart` verifies it:
///
/// * An address not registered for the type gives
///   [InterModuleStatusCode.notFound] with
///   [InterModuleErrorCode.endpointNotRegistered].
/// * A required parameter the provider declared that is absent or `null`
///   gives [InterModuleStatusCode.badRequest] with
///   [InterModuleErrorCode.missingRequiredParameters], and the provider is not
///   called. An empty string counts as present and reaches the provider.
/// * Only the provider's declared required parameters count; the consumer's
///   are ignored. Extra parameters reach the provider unchanged.
/// * The provider's response reaches the consumer unchanged.
/// * A provider that throws, or whose future fails, gives
///   [InterModuleStatusCode.internalError] with no data and no exception
///   details.
/// * Registering an address twice for the same type throws a
///   [DuplicateEndpointException].
/// * [getWidget] returns synchronously, with the exact widget the factory
///   built.
/// * [isRegistered] never invokes a provider.
/// * A call whose endpoint has an [InterModuleEndpoint.traceName] is timed,
///   and its name, duration, and status are recorded in the implementation's
///   own diagnostics.
///
/// Usage from a micro app:
/// ```dart
/// final response = await communication.request(
///   endpoint: const InterModuleEndpoint(
///     url: '/accounts/v1/details',
///     parameters: {'id': 'a1'},
///     traceName: 'transfers.account_details',
///   ),
/// );
///
/// final card = communication.getWidget(
///   endpoint: const InterModuleEndpoint(
///     url: '/accounts/v1/balance-card',
///     parameters: {'accountId': 'a1'},
///   ),
/// );
/// final child = card.data ?? const SizedBox.shrink();
/// ```
abstract interface class InterModuleCommunication {
  /// Registers a data endpoint.
  ///
  /// Micro apps never call it: the host calls it through
  /// [InterModuleProviderRegistration.registerProviders], after every micro
  /// app has initialized.
  ///
  /// Parameters:
  /// * [endpoint] - The address ([InterModuleEndpoint.url]) and the required
  ///   parameter names ([InterModuleEndpoint.requiredParameters]).
  /// * [handler] - The function that answers calls to the address.
  ///
  /// Throws a [DuplicateEndpointException] if the address is already
  /// registered as a data endpoint.
  void register({
    required InterModuleEndpoint endpoint,
    required InterModuleHandler handler,
  });

  /// Requests data from another micro app's endpoint.
  ///
  /// Parameters:
  /// * [endpoint] - The address ([InterModuleEndpoint.url]), the values to
  ///   send ([InterModuleEndpoint.parameters]), and an optional
  ///   [InterModuleEndpoint.traceName].
  ///
  /// Never throws: every outcome, including an unregistered address or a
  /// failing provider, is an [InterModuleCommunicationResponse].
  Future<InterModuleCommunicationResponse<Map<String, Object?>>> request({
    required InterModuleEndpoint endpoint,
  });

  /// Registers a UI endpoint.
  ///
  /// Micro apps never call it: the host calls it through
  /// [InterModuleProviderRegistration.registerProviders].
  ///
  /// Parameters:
  /// * [endpoint] - The address and the required parameter names.
  /// * [factory] - The function that builds the widget for each call.
  ///
  /// Throws a [DuplicateEndpointException] if the address is already
  /// registered as a UI endpoint.
  void registerWidget({
    required InterModuleEndpoint endpoint,
    required InterModuleWidgetFactory factory,
  });

  /// Gets a widget from another micro app's UI endpoint, synchronously.
  ///
  /// Parameters:
  /// * [endpoint] - The address and the values to send.
  ///
  /// Never throws. Loading and error states after the widget is returned
  /// belong to the micro app that provides it.
  InterModuleCommunicationResponse<Widget> getWidget({
    required InterModuleEndpoint endpoint,
  });

  /// Checks whether an address is registered for a type of endpoint.
  ///
  /// Parameters:
  /// * [url] - The address to look up, such as `/accounts/v1/details`.
  /// * [type] - The registry to look in.
  ///
  /// It never invokes a provider, so it is safe for deciding whether to show
  /// an entry point to another micro app.
  bool isRegistered({required String url, required EndpointType type});
}

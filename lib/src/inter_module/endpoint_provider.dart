import 'package:flutter/widgets.dart';

import 'inter_module_communication.dart';
import 'inter_module_endpoint.dart';
import 'inter_module_response.dart';

/// A micro app's offer of one data endpoint.
///
/// Micro apps declare providers instead of registering endpoints themselves;
/// hosts register them in bulk with `registerProviders`. Because a provider
/// is a class, it can be unit-tested by calling [handle] directly, without
/// Core or any communication implementation.
abstract interface class DataEndpointProvider {
  /// The address and the required parameter names. Its `parameters` are
  /// unused.
  InterModuleEndpoint get endpoint;

  /// Answers a request.
  ///
  /// When reached through [InterModuleCommunication], it is only called after
  /// the required-parameter check passes. It validates values itself, for
  /// example returning 400 `invalid_id` for an empty identifier, or 400
  /// `unauthenticated` / `forbidden` when it refuses access.
  Future<InterModuleCommunicationResponse<Map<String, Object?>>> handle(
    Map<String, Object?> parameters,
  );
}

/// A micro app's offer of one UI endpoint.
abstract interface class WidgetEndpointProvider {
  /// The address and the required parameter names. Its `parameters` are
  /// unused.
  InterModuleEndpoint get endpoint;

  /// Builds the element synchronously, without waiting for its own data.
  InterModuleCommunicationResponse<Widget> build(
    Map<String, Object?> parameters,
  );
}

/// Bulk registration of endpoint providers, used by hosts.
extension InterModuleProviderRegistration on InterModuleCommunication {
  /// Registers every provider: [data] providers as data endpoints and
  /// [widgets] providers as UI endpoints.
  ///
  /// Stops at the first `DuplicateEndpointException` and lets it propagate, so
  /// the host can stop startup.
  void registerProviders({
    Iterable<DataEndpointProvider> data = const [],
    Iterable<WidgetEndpointProvider> widgets = const [],
  }) {
    for (final provider in data) {
      register(endpoint: provider.endpoint, handler: provider.handle);
    }
    for (final provider in widgets) {
      registerWidget(endpoint: provider.endpoint, factory: provider.build);
    }
  }
}

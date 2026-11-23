/// @docImport '../exceptions/duplicate_endpoint_exception.dart';
/// @docImport 'inter_module_status.dart';
/// @docImport 'inter_module_value.dart';
library;

import 'package:flutter/widgets.dart';

import 'inter_module_communication.dart';
import 'inter_module_endpoint.dart';
import 'inter_module_response.dart';

/// Contract that a micro app implements to offer one data endpoint to other
/// micro apps.
///
/// Use this when another micro app needs data that your micro app owns, such
/// as an account's details. Declare the provider in your micro app's
/// `dataEndpoints`; consumers call it through
/// [InterModuleCommunication.request] without importing your micro app.
///
/// This is **not** registered by the micro app itself: providers are only
/// declared, and never passed to [InterModuleCommunication.register]
/// directly.
///
/// Built-in: the host registers every declared provider at once with
/// [InterModuleProviderRegistration.registerProviders], after all micro apps
/// have initialized. Because a provider is a plain class, it can be
/// unit-tested by calling [handle] directly, without Core.
///
/// Usage from a micro app:
/// ```dart
/// final class AccountDetailsProvider implements DataEndpointProvider {
///   AccountDetailsProvider(this._repository);
///
///   final AccountsRepository _repository;
///
///   @override
///   InterModuleEndpoint get endpoint => const InterModuleEndpoint(
///     url: '/accounts/v1/details',
///     requiredParameters: {'id'},
///   );
///
///   @override
///   Future<InterModuleCommunicationResponse<Map<String, Object?>>> handle(
///     Map<String, Object?> parameters,
///   ) async {
///     final account = await _repository.find(parameters['id']! as String);
///     if (account == null) {
///       return const InterModuleCommunicationResponse.failure(
///         statusCode: InterModuleStatusCode.notFound,
///         errorCode: 'account_not_found',
///       );
///     }
///     return InterModuleCommunicationResponse.success({
///       'id': account.id,
///       'name': account.name,
///     });
///   }
/// }
/// ```
abstract interface class DataEndpointProvider {
  /// Address and required parameter names of the endpoint.
  ///
  /// Only [InterModuleEndpoint.url] and
  /// [InterModuleEndpoint.requiredParameters] are read. The address follows
  /// `/<microAppId>/v<N>/<name>`; an incompatible change is published under a
  /// new version while the old one keeps serving its consumers.
  InterModuleEndpoint get endpoint;

  /// Answers a request from another micro app.
  ///
  /// When reached through [InterModuleCommunication.request], it is called
  /// only after every required parameter is present and not `null`. It
  /// validates the values itself, for example answering
  /// [InterModuleStatusCode.badRequest] with `invalid_id` for an empty
  /// identifier, or with [InterModuleErrorCode.unauthenticated] or
  /// [InterModuleErrorCode.forbidden] when it refuses access.
  ///
  /// Parameters:
  /// * [parameters] - The values the consumer sent, including any it was not
  ///   required to send.
  ///
  /// Returns a success whose data follows the payload rule (see
  /// [isInterModuleValue]), or a failure. If it throws, the consumer receives
  /// [InterModuleStatusCode.internalError] without the exception's details.
  Future<InterModuleCommunicationResponse<Map<String, Object?>>> handle(
    Map<String, Object?> parameters,
  );
}

/// Contract that a micro app implements to offer one piece of UI to other
/// micro apps.
///
/// Use this when another micro app should show a widget your micro app owns,
/// such as a balance card on the home screen. Declare the provider in your
/// micro app's `widgetEndpoints`; consumers get the widget through
/// [InterModuleCommunication.getWidget] without importing your micro app.
///
/// This is **not** a route: the widget is placed inside the consumer's own
/// screen. To open a full screen of another micro app, navigate to its path
/// instead.
///
/// Built-in: the host registers every declared provider with
/// [InterModuleProviderRegistration.registerProviders].
///
/// Usage from a micro app:
/// ```dart
/// final class BalanceCardProvider implements WidgetEndpointProvider {
///   @override
///   InterModuleEndpoint get endpoint => const InterModuleEndpoint(
///     url: '/accounts/v1/balance-card',
///     requiredParameters: {'accountId'},
///   );
///
///   @override
///   InterModuleCommunicationResponse<Widget> build(
///     Map<String, Object?> parameters,
///   ) => InterModuleCommunicationResponse.success(
///     BalanceCard(accountId: parameters['accountId']! as String),
///   );
/// }
/// ```
abstract interface class WidgetEndpointProvider {
  /// Address and required parameter names of the endpoint.
  ///
  /// Only [InterModuleEndpoint.url] and
  /// [InterModuleEndpoint.requiredParameters] are read.
  InterModuleEndpoint get endpoint;

  /// Builds the widget for another micro app, synchronously.
  ///
  /// It returns the widget without waiting for the widget's own data: the
  /// widget loads that data itself and owns its loading and error states.
  ///
  /// Parameters:
  /// * [parameters] - The values the consumer sent.
  ///
  /// If it throws, the consumer receives
  /// [InterModuleStatusCode.internalError].
  InterModuleCommunicationResponse<Widget> build(
    Map<String, Object?> parameters,
  );
}

/// Shortcuts that let a host register every endpoint provider in one step.
///
/// Use this in the host's startup, after every micro app has initialized. It
/// is the only way endpoints get registered.
///
/// Usage from a host:
/// ```dart
/// communication.registerProviders(
///   data: [for (final app in microApps) ...app.dataEndpoints],
///   widgets: [for (final app in microApps) ...app.widgetEndpoints],
/// );
/// ```
extension InterModuleProviderRegistration on InterModuleCommunication {
  /// Registers every provider as an endpoint.
  ///
  /// Parameters:
  /// * [data] - Optional data providers, registered with
  ///   [InterModuleCommunication.register]; defaults to none.
  /// * [widgets] - Optional UI providers, registered with
  ///   [InterModuleCommunication.registerWidget]; defaults to none.
  ///
  /// Stops at the first [DuplicateEndpointException] and lets it propagate,
  /// so the host can stop startup.
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

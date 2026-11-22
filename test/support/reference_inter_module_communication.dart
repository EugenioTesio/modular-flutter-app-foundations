import 'package:flutter/widgets.dart';
import 'package:foundations/foundations.dart';

/// Defects that a broken variant can switch on. The correct reference has
/// none; each broken variant enables exactly one.
class Defects {
  /// No defects.
  const Defects({
    this.ignoreRequiredParameters = false,
    this.rethrowHandlerErrors = false,
    this.leakExceptionText = false,
    this.acceptDuplicates = false,
    this.shareOneRegistry = false,
  });

  /// Skips the required-parameter check.
  final bool ignoreRequiredParameters;

  /// Lets handler and factory exceptions escape instead of returning 500.
  final bool rethrowHandlerErrors;

  /// Puts the exception text into the 500 response's error code.
  final bool leakExceptionText;

  /// Silently replaces an existing registration instead of throwing.
  final bool acceptDuplicates;

  /// Uses one registry for both endpoint types.
  final bool shareOneRegistry;
}

/// A correct, in-memory implementation of every contract behavior row
/// (B1–B13). Row B14 (trace diagnostics) belongs to real implementations.
class ReferenceInterModuleCommunication implements InterModuleCommunication {
  /// Creates the correct reference.
  ReferenceInterModuleCommunication() : _defects = const Defects();

  /// Creates a variant with the given [defects]; see the broken variants.
  ReferenceInterModuleCommunication.withDefects(this._defects);

  final Defects _defects;
  final _dataRegistry = <String, _Registration<InterModuleHandler>>{};
  final _widgetRegistry = <String, _Registration<InterModuleWidgetFactory>>{};
  final _sharedKeys = <String>{};

  @override
  void register({
    required InterModuleEndpoint endpoint,
    required InterModuleHandler handler,
  }) {
    _claim(endpoint.url, EndpointType.data, _dataRegistry.containsKey);
    _dataRegistry[endpoint.url] = _Registration(endpoint, handler);
  }

  @override
  void registerWidget({
    required InterModuleEndpoint endpoint,
    required InterModuleWidgetFactory factory,
  }) {
    _claim(endpoint.url, EndpointType.widget, _widgetRegistry.containsKey);
    _widgetRegistry[endpoint.url] = _Registration(endpoint, factory);
  }

  @override
  Future<InterModuleCommunicationResponse<Map<String, Object?>>> request({
    required InterModuleEndpoint endpoint,
  }) async {
    final registration = _dataRegistry[endpoint.url];
    if (registration == null) return _notRegistered();
    if (_missingRequired(registration.endpoint, endpoint.parameters)) {
      return _missingParameters();
    }
    try {
      return await registration.provider(endpoint.parameters);
    } catch (error) {
      if (_defects.rethrowHandlerErrors) rethrow;
      return _internalError(error);
    }
  }

  @override
  InterModuleCommunicationResponse<Widget> getWidget({
    required InterModuleEndpoint endpoint,
  }) {
    final registration = _widgetRegistry[endpoint.url];
    if (registration == null) return _notRegistered();
    if (_missingRequired(registration.endpoint, endpoint.parameters)) {
      return _missingParameters();
    }
    try {
      return registration.provider(endpoint.parameters);
    } catch (error) {
      if (_defects.rethrowHandlerErrors) rethrow;
      return _internalError(error);
    }
  }

  @override
  bool isRegistered({required String url, required EndpointType type}) {
    if (_defects.shareOneRegistry) return _sharedKeys.contains(url);
    return switch (type) {
      EndpointType.data => _dataRegistry.containsKey(url),
      EndpointType.widget => _widgetRegistry.containsKey(url),
    };
  }

  void _claim(String url, EndpointType type, bool Function(String) taken) {
    final duplicate = _defects.shareOneRegistry
        ? _sharedKeys.contains(url)
        : taken(url);
    if (duplicate && !_defects.acceptDuplicates) {
      throw DuplicateEndpointException(url: url, type: type);
    }
    _sharedKeys.add(url);
  }

  bool _missingRequired(
    InterModuleEndpoint declaration,
    Map<String, Object?> parameters,
  ) {
    if (_defects.ignoreRequiredParameters) return false;
    return declaration.requiredParameters.any(
      (name) => parameters[name] == null,
    );
  }

  InterModuleCommunicationResponse<T> _notRegistered<T>() =>
      InterModuleCommunicationResponse<T>.failure(
        statusCode: InterModuleStatusCode.notFound,
        errorCode: InterModuleErrorCode.endpointNotRegistered,
      );

  InterModuleCommunicationResponse<T> _missingParameters<T>() =>
      InterModuleCommunicationResponse<T>.failure(
        statusCode: InterModuleStatusCode.badRequest,
        errorCode: InterModuleErrorCode.missingRequiredParameters,
      );

  InterModuleCommunicationResponse<T> _internalError<T>(Object error) =>
      InterModuleCommunicationResponse<T>.failure(
        statusCode: InterModuleStatusCode.internalError,
        errorCode: _defects.leakExceptionText ? '$error' : null,
      );
}

class _Registration<P> {
  _Registration(this.endpoint, this.provider);

  final InterModuleEndpoint endpoint;
  final P provider;
}

import 'package:flutter/widgets.dart';
import 'package:foundations/foundations.dart';

/// A small in-memory [InterModuleCommunication] for the example.
///
/// Real apps get Core's implementation. This one passes the same conformance
/// check (`package:foundations/testing.dart`), so the example behaves like a
/// real host.
class ExampleInterModuleCommunication implements InterModuleCommunication {
  final _data = <String, (InterModuleEndpoint, InterModuleHandler)>{};
  final _widgets = <String, (InterModuleEndpoint, InterModuleWidgetFactory)>{};

  @override
  void register({
    required InterModuleEndpoint endpoint,
    required InterModuleHandler handler,
  }) {
    if (_data.containsKey(endpoint.url)) {
      throw DuplicateEndpointException(
        url: endpoint.url,
        type: EndpointType.data,
      );
    }
    _data[endpoint.url] = (endpoint, handler);
  }

  @override
  void registerWidget({
    required InterModuleEndpoint endpoint,
    required InterModuleWidgetFactory factory,
  }) {
    if (_widgets.containsKey(endpoint.url)) {
      throw DuplicateEndpointException(
        url: endpoint.url,
        type: EndpointType.widget,
      );
    }
    _widgets[endpoint.url] = (endpoint, factory);
  }

  @override
  Future<InterModuleCommunicationResponse<Map<String, Object?>>> request({
    required InterModuleEndpoint endpoint,
  }) async {
    final watch = Stopwatch()..start();
    final response = await _dispatch(endpoint);
    _trace(endpoint, response.statusCode, watch);
    return response;
  }

  @override
  InterModuleCommunicationResponse<Widget> getWidget({
    required InterModuleEndpoint endpoint,
  }) {
    final watch = Stopwatch()..start();
    final response = _dispatchWidget(endpoint);
    _trace(endpoint, response.statusCode, watch);
    return response;
  }

  @override
  bool isRegistered({required String url, required EndpointType type}) =>
      switch (type) {
        EndpointType.data => _data.containsKey(url),
        EndpointType.widget => _widgets.containsKey(url),
      };

  Future<InterModuleCommunicationResponse<Map<String, Object?>>> _dispatch(
    InterModuleEndpoint call,
  ) async {
    final registration = _data[call.url];
    if (registration == null) return _notRegistered();
    final (declaration, handler) = registration;
    if (_isMissingRequired(declaration, call.parameters)) {
      return _missingParameters();
    }
    try {
      return await handler(call.parameters);
    } catch (_) {
      return _internalError();
    }
  }

  InterModuleCommunicationResponse<Widget> _dispatchWidget(
    InterModuleEndpoint call,
  ) {
    final registration = _widgets[call.url];
    if (registration == null) return _notRegistered();
    final (declaration, factory) = registration;
    if (_isMissingRequired(declaration, call.parameters)) {
      return _missingParameters();
    }
    try {
      return factory(call.parameters);
    } catch (_) {
      return _internalError();
    }
  }

  bool _isMissingRequired(
    InterModuleEndpoint declaration,
    Map<String, Object?> parameters,
  ) => declaration.requiredParameters.any((name) => parameters[name] == null);

  /// Row B14: traced calls are timed and recorded in diagnostics.
  void _trace(InterModuleEndpoint call, int status, Stopwatch watch) {
    final name = call.traceName;
    if (name == null) return;
    debugPrint(
      '[trace] $name ${call.url} -> $status in ${watch.elapsedMilliseconds}ms',
    );
  }

  static InterModuleCommunicationResponse<T> _notRegistered<T>() =>
      InterModuleCommunicationResponse<T>.failure(
        statusCode: InterModuleStatusCode.notFound,
        errorCode: InterModuleErrorCode.endpointNotRegistered,
      );

  static InterModuleCommunicationResponse<T> _missingParameters<T>() =>
      InterModuleCommunicationResponse<T>.failure(
        statusCode: InterModuleStatusCode.badRequest,
        errorCode: InterModuleErrorCode.missingRequiredParameters,
      );

  static InterModuleCommunicationResponse<T> _internalError<T>() =>
      InterModuleCommunicationResponse<T>.failure(
        statusCode: InterModuleStatusCode.internalError,
      );
}

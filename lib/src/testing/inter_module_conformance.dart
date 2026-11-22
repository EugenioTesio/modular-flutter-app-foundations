import 'package:flutter/foundation.dart';

import '../exceptions/duplicate_endpoint_exception.dart';
import '../inter_module/inter_module_communication.dart';
import '../inter_module/inter_module_endpoint.dart';
import '../inter_module/inter_module_response.dart';
import '../inter_module/inter_module_status.dart';

/// The outcome of running one [ConformanceCase].
@immutable
final class ConformanceResult {
  /// The case passed.
  const ConformanceResult.pass() : passed = true, message = null;

  /// The case failed, for the reason in [message].
  const ConformanceResult.fail(String this.message) : passed = false;

  /// Whether the implementation behaved as the contract requires.
  final bool passed;

  /// Why the case failed; null when it passed.
  final String? message;
}

/// The body of a [ConformanceCase]. It calls `create` to get a fresh, empty
/// implementation, exercises it, and reports the result.
typedef ConformanceRun = Future<ConformanceResult> Function(
  InterModuleCommunication Function() create,
);

/// One verifiable behavior of the inter-module communication contract.
@immutable
final class ConformanceCase {
  /// Creates a case.
  const ConformanceCase({
    required this.id,
    required this.description,
    required this._body,
  });

  /// The case identifier, such as `C01`.
  final String id;

  /// What the case checks, in plain words.
  final String description;

  final ConformanceRun _body;

  /// Runs the case against a fresh implementation from [create].
  ///
  /// An exception escaping the implementation is reported as a failure, not
  /// thrown.
  Future<ConformanceResult> run(
    InterModuleCommunication Function() create,
  ) async {
    try {
      return await _body(create);
    } catch (error) {
      return ConformanceResult.fail('Unexpected exception: $error');
    }
  }
}

/// The conformance check for implementations of [InterModuleCommunication].
///
/// Core and standalone stubs run every case in their own test suites, for
/// example:
///
/// ```dart
/// for (final c in InterModuleConformance.cases) {
///   test('${c.id} ${c.description}', () async {
///     final result = await c.run(CoreInterModuleCommunication.new);
///     expect(result.passed, isTrue, reason: result.message);
///   });
/// }
/// ```
abstract final class InterModuleConformance {
  /// Every case, in identifier order.
  static const List<ConformanceCase> cases = [
    ConformanceCase(
      id: 'C01',
      description: 'A data request succeeds with the handler data',
      body: _c01DataSuccess,
    ),
    ConformanceCase(
      id: 'C02',
      description:
          'An absent required parameter yields 400 without calling '
          'the handler',
      body: _c02RequiredAbsent,
    ),
    ConformanceCase(
      id: 'C03',
      description:
          'A null required parameter yields 400 without calling '
          'the handler',
      body: _c03RequiredNull,
    ),
    ConformanceCase(
      id: 'C04',
      description: 'An empty-string required parameter reaches the handler',
      body: _c04EmptyStringReachesProvider,
    ),
    ConformanceCase(
      id: 'C05',
      description: "The consumer's required parameters are ignored",
      body: _c05ConsumerDeclarationIgnored,
    ),
    ConformanceCase(
      id: 'C06',
      description: 'Undeclared parameters reach the handler unchanged',
      body: _c06ExtraParametersPassThrough,
    ),
    ConformanceCase(
      id: 'C07',
      description: 'An unregistered data endpoint yields 404',
      body: _c07DataNotRegistered,
    ),
    ConformanceCase(
      id: 'C08',
      description: "A provider's own 404 reaches the consumer unchanged",
      body: _c08ProviderNotFoundPassesThrough,
    ),
    ConformanceCase(
      id: 'C09',
      description: 'A handler that throws yields 500 without exception details',
      body: _c09HandlerThrows,
    ),
    ConformanceCase(
      id: 'C10',
      description:
          'A handler whose future fails yields 500 without exception '
          'details',
      body: _c10HandlerFutureFails,
    ),
    ConformanceCase(
      id: 'C11',
      description:
          'Registering a data address twice throws '
          'DuplicateEndpointException',
      body: _c11DuplicateData,
    ),
    ConformanceCase(
      id: 'C17',
      description:
          'isRegistered reports each type separately and never calls '
          'a provider',
      body: _c17RegistrationCheck,
    ),
  ];
}

// ---------------------------------------------------------------------------
// Case bodies
// ---------------------------------------------------------------------------

const _url = '/conformance/v1/data';

typedef _DataResponse = InterModuleCommunicationResponse<Map<String, Object?>>;

/// Collects failed expectations for one case.
final class _Checks {
  final _failures = <String>[];

  void that(bool condition, String message) {
    if (!condition) _failures.add(message);
  }

  ConformanceResult get result => _failures.isEmpty
      ? const ConformanceResult.pass()
      : ConformanceResult.fail(_failures.join('; '));
}

/// A handler that counts its calls and returns [response].
final class _CountingHandler {
  _CountingHandler([this.response = const _DataResponse.success({'ok': true})]);

  final _DataResponse response;
  int calls = 0;
  Map<String, Object?>? received;

  Future<_DataResponse> call(Map<String, Object?> parameters) async {
    calls++;
    received = parameters;
    return response;
  }
}

void _expectMissingParameters(
  _Checks checks,
  _DataResponse response,
  _CountingHandler handler,
) {
  checks
    ..that(
      response.statusCode == 400,
      'expected 400, got ${response.statusCode}',
    )
    ..that(
      response.errorCode == InterModuleErrorCode.missingRequiredParameters,
      'expected missing_required_parameters, got ${response.errorCode}',
    )
    ..that(response.data == null, 'expected no data')
    ..that(handler.calls == 0, 'the handler must not be called');
}

void _expectInternalError(
  _Checks checks,
  _DataResponse response,
  String secret,
) {
  checks
    ..that(
      response.statusCode == 500,
      'expected 500, got ${response.statusCode}',
    )
    ..that(response.data == null, 'expected no data')
    ..that(
      !(response.errorCode ?? '').contains(secret),
      'the error code exposes exception details',
    );
}

Future<ConformanceResult> _c01DataSuccess(
  InterModuleCommunication Function() create,
) async {
  final checks = _Checks();
  final communication = create();
  const expected = {'id': '1', 'name': 'Example'};
  final handler = _CountingHandler(const _DataResponse.success(expected));
  communication.register(
    endpoint: const InterModuleEndpoint(url: _url, requiredParameters: {'id'}),
    handler: handler.call,
  );

  final response = await communication.request(
    endpoint: const InterModuleEndpoint(url: _url, parameters: {'id': '1'}),
  );

  checks
    ..that(
      response.statusCode == 200,
      'expected 200, got ${response.statusCode}',
    )
    ..that(
      mapEquals(response.data, expected),
      'unexpected data ${response.data}',
    )
    ..that(
      handler.calls == 1,
      'expected one handler call, got ${handler.calls}',
    );
  return checks.result;
}

Future<ConformanceResult> _c02RequiredAbsent(
  InterModuleCommunication Function() create,
) async {
  final checks = _Checks();
  final communication = create();
  final handler = _CountingHandler();
  communication.register(
    endpoint: const InterModuleEndpoint(url: _url, requiredParameters: {'id'}),
    handler: handler.call,
  );

  final response = await communication.request(
    endpoint: const InterModuleEndpoint(url: _url),
  );

  _expectMissingParameters(checks, response, handler);
  return checks.result;
}

Future<ConformanceResult> _c03RequiredNull(
  InterModuleCommunication Function() create,
) async {
  final checks = _Checks();
  final communication = create();
  final handler = _CountingHandler();
  communication.register(
    endpoint: const InterModuleEndpoint(url: _url, requiredParameters: {'id'}),
    handler: handler.call,
  );

  final response = await communication.request(
    endpoint: const InterModuleEndpoint(url: _url, parameters: {'id': null}),
  );

  _expectMissingParameters(checks, response, handler);
  return checks.result;
}

Future<ConformanceResult> _c04EmptyStringReachesProvider(
  InterModuleCommunication Function() create,
) async {
  final checks = _Checks();
  final communication = create();
  final handler = _CountingHandler(
    const _DataResponse.failure(statusCode: 400, errorCode: 'invalid_id'),
  );
  communication.register(
    endpoint: const InterModuleEndpoint(url: _url, requiredParameters: {'id'}),
    handler: handler.call,
  );

  final response = await communication.request(
    endpoint: const InterModuleEndpoint(url: _url, parameters: {'id': ''}),
  );

  checks
    ..that(handler.calls == 1, 'the handler must receive the empty string')
    ..that(handler.received?['id'] == '', 'the handler must receive ""')
    ..that(
      response.statusCode == 400,
      'expected 400, got ${response.statusCode}',
    )
    ..that(
      response.errorCode == 'invalid_id',
      "expected the provider's invalid_id, got ${response.errorCode}",
    );
  return checks.result;
}

Future<ConformanceResult> _c05ConsumerDeclarationIgnored(
  InterModuleCommunication Function() create,
) async {
  final checks = _Checks();
  final communication = create();
  final strict = _CountingHandler();
  final lenient = _CountingHandler();
  communication
    ..register(
      endpoint: const InterModuleEndpoint(
        url: _url,
        requiredParameters: {'id'},
      ),
      handler: strict.call,
    )
    ..register(
      endpoint: const InterModuleEndpoint(url: '/conformance/v1/lenient'),
      handler: lenient.call,
    );

  final relaxed = await communication.request(
    endpoint: const InterModuleEndpoint(url: _url),
  );
  final stricter = await communication.request(
    endpoint: const InterModuleEndpoint(
      url: '/conformance/v1/lenient',
      requiredParameters: {'x'},
    ),
  );

  checks
    ..that(
      relaxed.statusCode == 400 && strict.calls == 0,
      "a consumer can't relax the provider's required parameters",
    )
    ..that(
      stricter.statusCode == 200 && lenient.calls == 1,
      "a consumer's extra required parameters must not be enforced",
    );
  return checks.result;
}

Future<ConformanceResult> _c06ExtraParametersPassThrough(
  InterModuleCommunication Function() create,
) async {
  final checks = _Checks();
  final communication = create();
  final handler = _CountingHandler();
  communication.register(
    endpoint: const InterModuleEndpoint(url: _url, requiredParameters: {'id'}),
    handler: handler.call,
  );
  const sent = {'id': '1', 'extra': 'value', 'page': 2};

  await communication.request(
    endpoint: const InterModuleEndpoint(url: _url, parameters: sent),
  );

  checks.that(
    mapEquals(handler.received, sent),
    'the handler received ${handler.received} instead of $sent',
  );
  return checks.result;
}

Future<ConformanceResult> _c07DataNotRegistered(
  InterModuleCommunication Function() create,
) async {
  final checks = _Checks();
  final communication = create();

  final response = await communication.request(
    endpoint: const InterModuleEndpoint(url: _url),
  );

  checks
    ..that(
      response.statusCode == 404,
      'expected 404, got ${response.statusCode}',
    )
    ..that(
      response.errorCode == InterModuleErrorCode.endpointNotRegistered,
      'expected endpoint_not_registered, got ${response.errorCode}',
    )
    ..that(response.data == null, 'expected no data');
  return checks.result;
}

Future<ConformanceResult> _c08ProviderNotFoundPassesThrough(
  InterModuleCommunication Function() create,
) async {
  final checks = _Checks();
  final communication = create();
  final handler = _CountingHandler(
    const _DataResponse.failure(
      statusCode: 404,
      errorCode: 'details_not_found',
    ),
  );
  communication.register(
    endpoint: const InterModuleEndpoint(url: _url),
    handler: handler.call,
  );

  final response = await communication.request(
    endpoint: const InterModuleEndpoint(url: _url),
  );

  checks
    ..that(
      response.statusCode == 404,
      'expected 404, got ${response.statusCode}',
    )
    ..that(
      response.errorCode == 'details_not_found',
      "expected the provider's details_not_found, got ${response.errorCode}",
    );
  return checks.result;
}

Future<ConformanceResult> _c09HandlerThrows(
  InterModuleCommunication Function() create,
) async {
  const secret = 'conformance-secret-C09';
  final checks = _Checks();
  final communication = create();
  communication.register(
    endpoint: const InterModuleEndpoint(url: _url),
    handler: (_) => throw StateError(secret),
  );

  final response = await communication.request(
    endpoint: const InterModuleEndpoint(url: _url),
  );

  _expectInternalError(checks, response, secret);
  return checks.result;
}

Future<ConformanceResult> _c10HandlerFutureFails(
  InterModuleCommunication Function() create,
) async {
  const secret = 'conformance-secret-C10';
  final checks = _Checks();
  final communication = create();
  communication.register(
    endpoint: const InterModuleEndpoint(url: _url),
    handler: (_) => Future<_DataResponse>.error(StateError(secret)),
  );

  final response = await communication.request(
    endpoint: const InterModuleEndpoint(url: _url),
  );

  _expectInternalError(checks, response, secret);
  return checks.result;
}

Future<ConformanceResult> _c11DuplicateData(
  InterModuleCommunication Function() create,
) async {
  final checks = _Checks();
  final communication = create();
  const endpoint = InterModuleEndpoint(url: _url);
  communication.register(endpoint: endpoint, handler: _CountingHandler().call);

  Object? thrown;
  try {
    communication.register(
      endpoint: endpoint,
      handler: _CountingHandler().call,
    );
  } catch (error) {
    thrown = error;
  }

  checks
    ..that(
      thrown is DuplicateEndpointException,
      'expected DuplicateEndpointException',
    )
    ..that(
      thrown is! DuplicateEndpointException ||
          (thrown.url == _url && thrown.type == EndpointType.data),
      'the exception must name the address and the data type',
    );
  return checks.result;
}

Future<ConformanceResult> _c17RegistrationCheck(
  InterModuleCommunication Function() create,
) async {
  final checks = _Checks();
  final communication = create();
  final handler = _CountingHandler();
  checks.that(
    !communication.isRegistered(url: _url, type: EndpointType.data) &&
        !communication.isRegistered(url: _url, type: EndpointType.widget),
    'nothing may be registered yet',
  );

  communication.register(
    endpoint: const InterModuleEndpoint(url: _url),
    handler: handler.call,
  );

  checks
    ..that(
      communication.isRegistered(url: _url, type: EndpointType.data),
      'the data endpoint must be reported as registered',
    )
    ..that(
      !communication.isRegistered(url: _url, type: EndpointType.widget),
      'a data registration must not count as a UI registration',
    )
    ..that(handler.calls == 0, 'isRegistered must not call the provider');
  return checks.result;
}

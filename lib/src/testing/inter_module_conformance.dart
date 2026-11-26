import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../exceptions/duplicate_endpoint_exception.dart';
import '../inter_module/inter_module_communication.dart';
import '../inter_module/inter_module_endpoint.dart';
import '../inter_module/inter_module_response.dart';
import '../inter_module/inter_module_status.dart';

/// Value that reports whether an implementation passed one
/// [ConformanceCase].
///
/// Use this to turn a case into a test assertion: expect [passed] to be
/// `true`, and show [message] as the reason when it isn't.
///
/// This is **not** a test-framework result: it depends on no test package,
/// so each test suite decides how to report it.
///
/// Built-in: [ConformanceCase.run] returns one, and turns an exception that
/// escapes the implementation into a failed result instead of throwing it.
///
/// Usage from a host's test suite:
/// ```dart
/// final result = await InterModuleConformance.cases.first.run(
///   CoreInterModuleCommunication.new,
/// );
/// expect(result.passed, isTrue, reason: result.message);
/// ```
@immutable
final class ConformanceResult {
  /// Creates a result for a case that passed, with no [message].
  const ConformanceResult.pass() : passed = true, message = null;

  /// Creates a result for a case that failed.
  ///
  /// Parameters:
  /// * [message] - Why the case failed, naming every broken expectation.
  const ConformanceResult.fail(String this.message) : passed = false;

  /// Whether the implementation behaved as the contract requires.
  final bool passed;

  /// Optional reason the case failed; `null` when it passed.
  final String? message;
}

/// Function that runs the body of a [ConformanceCase].
///
/// Use this only to read how cases are built: each one calls `create` for a
/// fresh, empty implementation, exercises it, and returns a
/// [ConformanceResult].
///
/// This is **not** something a host writes: [InterModuleConformance.cases]
/// holds every case, and hosts call [ConformanceCase.run].
typedef ConformanceRun = Future<ConformanceResult> Function(
  InterModuleCommunication Function() create,
);

/// Value that describes one behavior of the [InterModuleCommunication]
/// contract and checks it.
///
/// Use this to run one check against an implementation, usually by looping
/// over [InterModuleConformance.cases] and creating one test per case.
///
/// This is **not** a test: it registers nothing with a test framework, and
/// it never throws. Each [run] gets a fresh implementation, so cases don't
/// affect each other.
///
/// Built-in: Foundations defines every case in
/// [InterModuleConformance.cases]; hosts don't create their own.
///
/// Usage from a host's test suite:
/// ```dart
/// final conformanceCase = InterModuleConformance.cases.first;
/// test('${conformanceCase.id} ${conformanceCase.description}', () async {
///   final result = await conformanceCase.run(
///     CoreInterModuleCommunication.new,
///   );
///   expect(result.passed, isTrue, reason: result.message);
/// });
/// ```
@immutable
final class ConformanceCase {
  /// Creates a conformance case.
  ///
  /// Parameters:
  /// * [id] - The case identifier, such as `C01`.
  /// * [description] - What the case checks, in plain words.
  /// * `body` - The [ConformanceRun] that performs the check.
  const ConformanceCase({
    required this.id,
    required this.description,
    required this._body,
  });

  /// Identifier of the case, such as `C01`, stable across releases.
  final String id;

  /// Plain description of the behavior the case checks.
  final String description;

  final ConformanceRun _body;

  /// Runs the case against a fresh implementation.
  ///
  /// Parameters:
  /// * [create] - Builds a new, empty [InterModuleCommunication], such as
  ///   its constructor tear-off. A case may call it more than once.
  ///
  /// Returns a [ConformanceResult]. An exception that escapes the
  /// implementation is reported as a failed result naming the exception; it
  /// is never thrown.
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

/// Contract check that every [InterModuleCommunication] implementation must
/// pass.
///
/// Use this in the test suite of Core, a standalone stub, or any other
/// implementation, so they all route requests, validate required
/// parameters, report errors, and refuse duplicate addresses the same way.
///
/// This is **not** a test of Foundations itself, and it is not exported from
/// `package:foundations/foundations.dart`: import
/// `package:foundations/testing.dart` from test code only.
///
/// Built-in: the cases cover data requests (success, missing or null
/// required parameters, extra parameters, unregistered addresses, provider
/// failures passed through, handlers that throw or fail), UI requests (the
/// same rules, answered synchronously), duplicate registration throwing a
/// [DuplicateEndpointException], separate data and UI registries, and
/// `isRegistered`.
///
/// Rules:
/// * An implementation conforms only when every case passes.
/// * Run every case, not a chosen few: a new case in a later release is a
///   new requirement of the contract.
/// * The cases check that an implementation never exposes a handler's
///   exception details in a response; a failed [ConformanceResult] may name
///   the exception, since it only reaches test output.
///
/// Usage from a host's test suite:
/// ```dart
/// for (final conformanceCase in InterModuleConformance.cases) {
///   test('${conformanceCase.id} ${conformanceCase.description}', () async {
///     final result = await conformanceCase.run(
///       CoreInterModuleCommunication.new,
///     );
///     expect(result.passed, isTrue, reason: result.message);
///   });
/// }
/// ```
abstract final class InterModuleConformance {
  /// Every conformance case, in identifier order.
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
      id: 'C12',
      description:
          'A UI request returns the exact widget synchronously with 200',
      body: _c12WidgetSuccess,
    ),
    ConformanceCase(
      id: 'C13',
      description:
          'An absent or null required UI parameter yields 400 without '
          'calling the factory',
      body: _c13WidgetRequiredMissing,
    ),
    ConformanceCase(
      id: 'C14',
      description: 'An unregistered UI endpoint yields 404',
      body: _c14WidgetNotRegistered,
    ),
    ConformanceCase(
      id: 'C15',
      description: 'A factory that throws yields 500 without exception details',
      body: _c15WidgetFactoryThrows,
    ),
    ConformanceCase(
      id: 'C16',
      description:
          'Registering a UI address twice throws, and data and UI '
          'registries are separate',
      body: _c16WidgetRegistries,
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
  InterModuleCommunicationResponse<Object> response,
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

const _widgetUrl = '/conformance/v1/widget';

typedef _WidgetResponse = InterModuleCommunicationResponse<Widget>;

/// A UI factory that counts its calls and returns [widget].
final class _CountingFactory {
  _CountingFactory([this.widget = const SizedBox()]);

  final Widget widget;
  int calls = 0;

  _WidgetResponse call(Map<String, Object?> parameters) {
    calls++;
    return _WidgetResponse.success(widget);
  }
}

Future<ConformanceResult> _c12WidgetSuccess(
  InterModuleCommunication Function() create,
) async {
  final checks = _Checks();
  final communication = create();
  // A fresh, non-const instance, so identity is meaningful.
  final widget = SizedBox(key: UniqueKey());
  final factory = _CountingFactory(widget);
  communication.registerWidget(
    endpoint: const InterModuleEndpoint(
      url: _widgetUrl,
      requiredParameters: {'id'},
    ),
    factory: factory.call,
  );

  // getWidget is synchronous: the factory has run when it returns.
  final response = communication.getWidget(
    endpoint: const InterModuleEndpoint(
      url: _widgetUrl,
      parameters: {'id': '1'},
    ),
  );

  checks
    ..that(
      response.statusCode == 200,
      'expected 200, got ${response.statusCode}',
    )
    ..that(
      identical(response.data, widget),
      'data must be the exact widget the factory built',
    )
    ..that(
      factory.calls == 1,
      'expected one factory call, got ${factory.calls}',
    );
  return checks.result;
}

Future<ConformanceResult> _c13WidgetRequiredMissing(
  InterModuleCommunication Function() create,
) async {
  final checks = _Checks();
  final communication = create();
  final factory = _CountingFactory();
  communication.registerWidget(
    endpoint: const InterModuleEndpoint(
      url: _widgetUrl,
      requiredParameters: {'id'},
    ),
    factory: factory.call,
  );

  for (final (label, parameters) in const [
    ('absent', <String, Object?>{}),
    ('null', <String, Object?>{'id': null}),
  ]) {
    final response = communication.getWidget(
      endpoint: InterModuleEndpoint(url: _widgetUrl, parameters: parameters),
    );
    checks
      ..that(
        response.statusCode == 400,
        '$label: expected 400, got ${response.statusCode}',
      )
      ..that(
        response.errorCode == InterModuleErrorCode.missingRequiredParameters,
        '$label: expected missing_required_parameters, '
        'got ${response.errorCode}',
      )
      ..that(response.data == null, '$label: expected no widget');
  }
  checks.that(factory.calls == 0, 'the factory must not be called');
  return checks.result;
}

Future<ConformanceResult> _c14WidgetNotRegistered(
  InterModuleCommunication Function() create,
) async {
  final checks = _Checks();
  final communication = create();

  final response = communication.getWidget(
    endpoint: const InterModuleEndpoint(url: _widgetUrl),
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
    ..that(response.data == null, 'expected no widget');
  return checks.result;
}

Future<ConformanceResult> _c15WidgetFactoryThrows(
  InterModuleCommunication Function() create,
) async {
  const secret = 'conformance-secret-C15';
  final checks = _Checks();
  final communication = create();
  communication.registerWidget(
    endpoint: const InterModuleEndpoint(url: _widgetUrl),
    factory: (_) => throw StateError(secret),
  );

  final response = communication.getWidget(
    endpoint: const InterModuleEndpoint(url: _widgetUrl),
  );

  _expectInternalError(checks, response, secret);
  return checks.result;
}

Future<ConformanceResult> _c16WidgetRegistries(
  InterModuleCommunication Function() create,
) async {
  final checks = _Checks();

  // A second UI registration of the same address throws.
  final duplicates = create();
  const endpoint = InterModuleEndpoint(url: _widgetUrl);
  duplicates.registerWidget(
    endpoint: endpoint,
    factory: _CountingFactory().call,
  );
  Object? thrown;
  try {
    duplicates.registerWidget(
      endpoint: endpoint,
      factory: _CountingFactory().call,
    );
  } catch (error) {
    thrown = error;
  }
  checks
    ..that(
      thrown is DuplicateEndpointException,
      'expected DuplicateEndpointException for a second UI registration',
    )
    ..that(
      thrown is! DuplicateEndpointException ||
          (thrown.url == _widgetUrl && thrown.type == EndpointType.widget),
      'the exception must name the address and the widget type',
    );

  // One address registered as data and as UI: both work.
  final separate = create();
  final handler = _CountingHandler();
  final factory = _CountingFactory();
  try {
    separate
      ..register(endpoint: endpoint, handler: handler.call)
      ..registerWidget(endpoint: endpoint, factory: factory.call);
  } on Object {
    checks.that(false, 'registering one address as data and as UI threw');
    return checks.result;
  }
  final data = await separate.request(endpoint: endpoint);
  final widget = separate.getWidget(endpoint: endpoint);
  checks
    ..that(
      data.statusCode == 200 && handler.calls == 1,
      'the data endpoint must still answer',
    )
    ..that(
      widget.statusCode == 200 && factory.calls == 1,
      'the UI endpoint must still answer',
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

// Feature: The API client contract (FR-039; data-model.md ApiRequest.path,
// ApiRequest.body, ApiException.type, ApiResponse.statusCode).
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';

import '../support/fakes.dart';

/// Matches every failure type without a default branch, so adding a type
/// breaks compilation here.
String describeFailure(ApiExceptionType type) => switch (type) {
  ApiExceptionType.noConnectivity => 'offline',
  ApiExceptionType.timeout => 'slow',
  ApiExceptionType.unauthorized => 'sign in again',
  ApiExceptionType.clientError => 'bad request',
  ApiExceptionType.serverError => 'try later',
  ApiExceptionType.badCertificate => 'insecure connection',
  ApiExceptionType.invalidRequest => 'could not send',
  ApiExceptionType.invalidResponse => 'unexpected answer',
  ApiExceptionType.unknown => 'something went wrong',
};

void main() {
  group('Given a request built with only a method and a path', () {
    const request = ApiRequest(method: ApiMethod.get, path: '/accounts');

    test('When its optional fields are read, '
        'Then queryParams and headers are empty and body is null', () {
      // When
      final queryParams = request.queryParams;
      final headers = request.headers;
      final body = request.body;

      // Then
      expect(queryParams, isEmpty);
      expect(headers, isEmpty);
      expect(body, isNull);
      expect(request.path, '/accounts');
    });
  });

  group('Given two requests built separately with the same content', () {
    const body = {'amount': 10};
    final first = ApiRequest(
      method: ApiMethod.post,
      path: '/transfers',
      queryParams: {'dryRun': 'true'},
      headers: {'X-Request-Id': '1'},
      body: body,
    );
    final second = ApiRequest(
      method: ApiMethod.post,
      path: '/transfers',
      queryParams: {'dryRun': 'true'},
      headers: {'X-Request-Id': '1'},
      body: body,
    );

    test('When they are compared, '
        'Then query parameters and headers are compared by content', () {
      // When
      final equal = first == second;

      // Then
      expect(equal, isTrue);
      expect(first.hashCode, second.hashCode);
    });

    test('When one body is a different object, '
        'Then they are not equal, because the body is compared with ==', () {
      // Given
      final other = ApiRequest(
        method: ApiMethod.post,
        path: '/transfers',
        queryParams: {'dryRun': 'true'},
        headers: {'X-Request-Id': '1'},
        body: {'amount': 10},
      );

      // When
      final equal = first == other;

      // Then
      expect(equal, isFalse);
    });
  });

  group('Given an API client that records the requests it is sent', () {
    late RecordingApiClient client;

    setUp(() {
      client = RecordingApiClient();
    });

    const queryParams = {'page': '2'};
    const headers = {'X-Trace': 't'};
    const body = {'name': 'Savings'};

    final cases =
        <
          String,
          (
            ApiMethod,
            Future<Result<ApiResponse, ApiException>> Function(ApiClient),
            Object?,
          )
        >{
          'get': (
            ApiMethod.get,
            (c) =>
                c.get('/accounts', queryParams: queryParams, headers: headers),
            null,
          ),
          'post': (
            ApiMethod.post,
            (c) => c.post(
              '/accounts',
              body: body,
              queryParams: queryParams,
              headers: headers,
            ),
            body,
          ),
          'put': (
            ApiMethod.put,
            (c) => c.put(
              '/accounts',
              body: body,
              queryParams: queryParams,
              headers: headers,
            ),
            body,
          ),
          'patch': (
            ApiMethod.patch,
            (c) => c.patch(
              '/accounts',
              body: body,
              queryParams: queryParams,
              headers: headers,
            ),
            body,
          ),
          'delete': (
            ApiMethod.delete,
            (c) => c.delete(
              '/accounts',
              queryParams: queryParams,
              headers: headers,
            ),
            null,
          ),
        };

    for (final MapEntry(key: name, value: (method, call, expectedBody))
        in cases.entries) {
      test('When the $name shortcut is called, '
          'Then send receives a ${method.name} request with the same path, '
          'queryParams, headers, and body', () async {
        // When
        await call(client);

        // Then
        expect(client.requests, [
          ApiRequest(
            method: method,
            path: '/accounts',
            queryParams: queryParams,
            headers: headers,
            body: expectedBody,
          ),
        ]);
      });
    }

    test('When a shortcut is called with no options, '
        'Then the request has empty queryParams and headers', () async {
      // When
      await client.get('/accounts');

      // Then
      expect(client.requests.single.queryParams, isEmpty);
      expect(client.requests.single.headers, isEmpty);
    });
  });

  group('Given every API exception type', () {
    test('When each is described exhaustively, '
        'Then every type has its own description', () {
      // When
      final descriptions = ApiExceptionType.values.map(describeFailure).toSet();

      // Then
      expect(ApiExceptionType.values, hasLength(9));
      expect(descriptions, hasLength(ApiExceptionType.values.length));
    });
  });

  group('Given a client error failure with a status and a body', () {
    const failure = ApiException(
      type: ApiExceptionType.clientError,
      statusCode: 422,
      body: {'field': 'amount'},
    );

    test('When it is compared with an equal failure, '
        'Then they are equal and keep the status and body', () {
      // Given
      const same = ApiException(
        type: ApiExceptionType.clientError,
        statusCode: 422,
        body: {'field': 'amount'},
      );

      // When
      final equal = failure == same;

      // Then
      expect(equal, isTrue);
      expect(failure.hashCode, same.hashCode);
      expect(failure.type, ApiExceptionType.clientError);
      expect(failure.statusCode, 422);
    });
  });

  group('Given a response with a status code', () {
    const response = ApiResponse(statusCode: 201, body: {'id': 'a1'});

    test('When its fields are read, '
        'Then the status is kept and headers default to empty', () {
      // When
      final statusCode = response.statusCode;

      // Then
      expect(statusCode, 201);
      expect(response.headers, isEmpty);
      expect(response, const ApiResponse(statusCode: 201, body: {'id': 'a1'}));
    });
  });
}

// Feature: Inter-module response (FR-008, FR-011; data-model.md
// InterModuleCommunicationResponse.statusCode, .data, .errorCode, .isSuccess).
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';

void main() {
  group('Given responses at the edges of the success range', () {
    test('When isSuccess is read, '
        'Then it is true exactly for statuses from 200 to 299', () {
      // Given
      const statuses = {199: false, 200: true, 299: true, 300: false};

      // When
      final results = {
        for (final status in statuses.keys)
          status: InterModuleCommunicationResponse<Object>(statusCode: status)
              .isSuccess,
      };

      // Then
      expect(results, statuses);
    });
  });

  group('Given a success response', () {
    const response =
        InterModuleCommunicationResponse<Map<String, Object?>>.success({
          'id': '123',
          'name': 'Example details',
        });

    test('When it is read, '
        'Then it has status 200, the data, and no error code', () {
      // When
      final status = response.statusCode;

      // Then
      expect(status, InterModuleStatusCode.ok);
      expect(response.data, {'id': '123', 'name': 'Example details'});
      expect(response.errorCode, isNull);
      expect(response.isSuccess, isTrue);
    });
  });

  group('Given a failure response', () {
    const response =
        InterModuleCommunicationResponse<Map<String, Object?>>.failure(
          statusCode: InterModuleStatusCode.notFound,
          errorCode: InterModuleErrorCode.endpointNotRegistered,
        );

    test('When it is read, '
        'Then it carries the status and error code and no data', () {
      // When
      final status = response.statusCode;

      // Then
      expect(status, 404);
      expect(response.errorCode, 'endpoint_not_registered');
      expect(response.data, isNull);
      expect(response.isSuccess, isFalse);
    });

    test('When it is built with a success status, '
        'Then an assertion error is raised', () {
      // When
      InterModuleCommunicationResponse<Object> build() =>
          InterModuleCommunicationResponse<Object>.failure(statusCode: 200 + 0);

      // Then
      expect(build, throwsAssertionError);
    });
  });
}

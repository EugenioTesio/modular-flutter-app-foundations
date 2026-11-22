// Feature: Published statuses and shared error codes (FR-011, FR-012;
// data-model.md "Shared error codes").
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';

void main() {
  group('Given the published inter-module statuses', () {
    test(
      'When their values are read, Then they are 200, 400, 404, and 500',
      () {
        // When
        final statuses = [
          InterModuleStatusCode.ok,
          InterModuleStatusCode.badRequest,
          InterModuleStatusCode.notFound,
          InterModuleStatusCode.internalError,
        ];

        // Then
        expect(statuses, [200, 400, 404, 500]);
      },
    );
  });

  group('Given the shared error codes', () {
    test('When their values are read, Then they match the published text', () {
      // When
      final codes = [
        InterModuleErrorCode.missingRequiredParameters,
        InterModuleErrorCode.endpointNotRegistered,
        InterModuleErrorCode.unauthenticated,
        InterModuleErrorCode.forbidden,
      ];

      // Then
      expect(codes, [
        'missing_required_parameters',
        'endpoint_not_registered',
        'unauthenticated',
        'forbidden',
      ]);
    });
  });
}

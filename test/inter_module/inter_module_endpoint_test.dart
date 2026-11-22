// Feature: Inter-module endpoint description (FR-007, FR-013; data-model.md
// InterModuleEndpoint.url, .parameters, .requiredParameters, .traceName).
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';

void main() {
  group('Given an endpoint built with only a url', () {
    const endpoint = InterModuleEndpoint(url: '/module-b/v1/details');

    test(
      'When its optional fields are read, '
      'Then parameters and requiredParameters are empty and traceName is null',
      () {
        // When
        final parameters = endpoint.parameters;
        final required = endpoint.requiredParameters;
        final traceName = endpoint.traceName;

        // Then
        expect(parameters, isEmpty);
        expect(required, isEmpty);
        expect(traceName, isNull);
        expect(endpoint.url, '/module-b/v1/details');
      },
    );
  });

  group('Given two endpoints built separately with the same content', () {
    final first = InterModuleEndpoint(
      url: '/module-b/v1/details',
      parameters: {'id': '123', 'page': 2},
      requiredParameters: {'id'},
      traceName: 'module_a.details',
    );
    final second = InterModuleEndpoint(
      url: '/module-b/v1/details',
      parameters: {'page': 2, 'id': '123'},
      requiredParameters: {'id'},
      traceName: 'module_a.details',
    );

    test('When they are compared, '
        'Then they are equal and share a hash code', () {
      // When
      final equal = first == second;

      // Then
      expect(equal, isTrue);
      expect(first.hashCode, second.hashCode);
    });
  });

  group('Given a reference endpoint', () {
    const reference = InterModuleEndpoint(
      url: '/module-b/v1/details',
      parameters: {'id': '123'},
      requiredParameters: {'id'},
      traceName: 'module_a.details',
    );

    test('When an endpoint differs in any single field, '
        'Then it is not equal to the reference', () {
      // Given
      const variants = [
        InterModuleEndpoint(
          url: '/module-b/v2/details',
          parameters: {'id': '123'},
          requiredParameters: {'id'},
          traceName: 'module_a.details',
        ),
        InterModuleEndpoint(
          url: '/module-b/v1/details',
          parameters: {'id': '456'},
          requiredParameters: {'id'},
          traceName: 'module_a.details',
        ),
        InterModuleEndpoint(
          url: '/module-b/v1/details',
          parameters: {'id': '123'},
          requiredParameters: {'id', 'page'},
          traceName: 'module_a.details',
        ),
        InterModuleEndpoint(
          url: '/module-b/v1/details',
          parameters: {'id': '123'},
          requiredParameters: {'id'},
        ),
      ];

      // When
      final equalities = variants.map((variant) => variant == reference);

      // Then
      expect(equalities, everyElement(isFalse));
    });
  });
}

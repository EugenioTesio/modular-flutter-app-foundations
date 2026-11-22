// Feature: Inter-module payload rule (data-model.md "Shared rules → Payload
// rule"; FR-009, FR-023).
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';

class _Custom {}

void main() {
  group('Given a conforming value', () {
    test('When it is null or a primitive, Then it is accepted', () {
      // Given
      const values = <Object?>[null, true, 42, 3.14, '', 'text'];

      // When
      final results = values.map(isInterModuleValue);

      // Then
      expect(results, everyElement(isTrue));
    });

    test('When it is an empty list or String-keyed map, '
        'Then it is accepted', () {
      // Given
      final values = <Object?>[<Object?>[], <String, Object?>{}];

      // When
      final results = values.map(isInterModuleValue);

      // Then
      expect(results, everyElement(isTrue));
    });

    test('When it nests lists and maps of primitives, '
        'Then it is accepted', () {
      // Given
      final value = {
        'id': '123',
        'amount': 10.5,
        'tags': ['a', 'b', null, true],
        'owner': {
          'name': 'Ana',
          'accounts': [
            {'iban': 'X1', 'active': true},
          ],
        },
      };

      // When
      final result = isInterModuleValue(value);

      // Then
      expect(result, isTrue);
    });
  });

  group('Given a non-conforming value', () {
    test('When it is a custom object, a date, or a duration, '
        'Then it is rejected', () {
      // Given
      final values = <Object?>[
        _Custom(),
        DateTime(2026),
        const Duration(seconds: 1),
      ];

      // When
      final results = values.map(isInterModuleValue);

      // Then
      expect(results, everyElement(isFalse));
    });

    test('When it is a map with non-String keys, Then it is rejected', () {
      // Given
      final values = <Object?>[
        {1: 'a'},
        <Object?, Object?>{null: 1},
      ];

      // When
      final results = values.map(isInterModuleValue);

      // Then
      expect(results, everyElement(isFalse));
    });

    test('When a custom object is nested anywhere, Then it is rejected', () {
      // Given
      final values = <Object?>[
        [1, _Custom()],
        {'a': _Custom()},
        {
          'a': [
            {'b': _Custom()},
          ],
        },
      ];

      // When
      final results = values.map(isInterModuleValue);

      // Then
      expect(results, everyElement(isFalse));
    });

    test('When it is a set or another non-list iterable, '
        'Then it is rejected', () {
      // Given
      final values = <Object?>[
        {'a', 'b'},
        [1, 2].map((e) => e),
      ];

      // When
      final results = values.map(isInterModuleValue);

      // Then
      expect(results, everyElement(isFalse));
    });

    test('When a list contains itself, Then it is rejected', () {
      // Given
      final list = <Object?>[1];
      list.add(list);

      // When
      final result = isInterModuleValue(list);

      // Then
      expect(result, isFalse);
    });
  });
}

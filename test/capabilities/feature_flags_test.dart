// Feature: Typed feature flags with defaults and change notifications
// (FR-040, FR-051; data-model.md FeatureFlag.key, FeatureFlag.defaultValue).
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';

import '../support/fakes.dart';

const _newDashboard = BoolFeatureFlag(
  key: 'accounts.new_dashboard',
  defaultValue: false,
);
const _greeting = StringFeatureFlag(
  key: 'accounts.greeting',
  defaultValue: 'Hello',
);
const _maxItems = NumberFeatureFlag(
  key: 'accounts.max_items',
  defaultValue: 10,
);

/// Matches every flag variant without a default branch.
String typeOf(FeatureFlag<Object> flag) => switch (flag) {
  BoolFeatureFlag() => 'bool',
  StringFeatureFlag() => 'string',
  NumberFeatureFlag() => 'number',
};

void main() {
  group('Given the three typed flag definitions', () {
    test('When their fields are read, '
        'Then each keeps its key and a default of its own type', () {
      // When
      final bool boolDefault = _newDashboard.defaultValue;
      final String stringDefault = _greeting.defaultValue;
      final num numberDefault = _maxItems.defaultValue;

      // Then
      expect(_newDashboard.key, 'accounts.new_dashboard');
      expect(boolDefault, isFalse);
      expect(stringDefault, 'Hello');
      expect(numberDefault, 10);
      expect(
        <FeatureFlag<Object>>[_newDashboard, _greeting, _maxItems].map(typeOf),
        ['bool', 'string', 'number'],
      );
    });

    test('When two definitions with the same content are compared, '
        'Then they are equal', () {
      // Given
      // ignore: prefer_const_constructors
      final copy = BoolFeatureFlag(
        key: 'accounts.new_dashboard',
        defaultValue: false,
      );

      // When
      final equal = copy == _newDashboard;

      // Then
      expect(equal, isTrue);
      expect(copy.hashCode, _newDashboard.hashCode);
    });
  });

  group('Given a flag provider that knows none of the flags', () {
    final flags = InMemoryFeatureFlags();

    test('When each flag is read, Then its default is returned', () {
      // When
      final values = [
        flags.valueOf(_newDashboard),
        flags.valueOf(_greeting),
        flags.valueOf(_maxItems),
      ];

      // Then
      expect(values, [false, 'Hello', 10]);
    });
  });

  group('Given a flag provider holding values of the wrong kind', () {
    final flags = InMemoryFeatureFlags({
      'accounts.new_dashboard': 'yes',
      'accounts.greeting': 3,
      'accounts.max_items': true,
    });

    test('When each flag is read, Then its default is returned', () {
      // When
      final values = [
        flags.valueOf(_newDashboard),
        flags.valueOf(_greeting),
        flags.valueOf(_maxItems),
      ];

      // Then
      expect(values, [false, 'Hello', 10]);
    });
  });

  group('Given a flag provider holding values of the right kind', () {
    final flags = InMemoryFeatureFlags({
      'accounts.new_dashboard': true,
      'accounts.greeting': 'Hi',
      'accounts.max_items': 25,
    });

    test('When each flag is read, Then the provider value is returned', () {
      // When
      final values = [
        flags.valueOf(_newDashboard),
        flags.valueOf(_greeting),
        flags.valueOf(_maxItems),
      ];

      // Then
      expect(values, [true, 'Hi', 25]);
    });
  });

  group('Given a consumer listening for flag changes', () {
    test('When the provider refreshes its values, '
        'Then the consumer is notified and re-reads the new value', () async {
      // Given
      final flags = InMemoryFeatureFlags();
      final reads = <bool>[];
      final subscription = flags.changes.listen(
        (_) => reads.add(flags.valueOf(_newDashboard)),
      );

      // When
      flags.refresh({'accounts.new_dashboard': true});
      await pumpEventQueue();

      // Then
      expect(reads, [true]);
      await subscription.cancel();
      await flags.close();
    });
  });
}

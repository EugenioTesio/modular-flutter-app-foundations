// Feature: Foundations dependency allow-list (FR-003, FR-043, FR-053, SC-001).
// Runtime dependencies are limited to the Flutter SDK, the design system, and
// switchable_state. Adapters, state libraries, and router packages may only be
// development dependencies.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// Runtime dependencies Foundations is allowed to have.
const _allowedRuntime = {'flutter', 'design_system', 'switchable_state'};

/// Packages that must never be runtime dependencies.
bool _isDevOnly(String name) =>
    name.startsWith('switchable_state_') ||
    const {
      'flutter_riverpod',
      'riverpod',
      'flutter_bloc',
      'bloc',
      'provider',
      'get',
      'mobx',
      'flutter_mobx',
      'go_router',
    }.contains(name);

void main() {
  group('Given the Foundations pubspec.yaml', () {
    late YamlMap dependencies;

    setUp(() {
      final pubspec =
          loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
      dependencies = pubspec['dependencies'] as YamlMap? ?? YamlMap();
    });

    test('When its runtime dependencies are read, '
        'Then they are within {flutter, design_system, switchable_state}', () {
      // When
      final runtime = dependencies.keys.cast<String>().toSet();

      // Then
      expect(runtime.difference(_allowedRuntime), isEmpty);
    });

    test('When the switchable_state constraint is read, '
        'Then it is pinned to exactly 0.1.0', () {
      // When
      final constraint = dependencies['switchable_state'];

      // Then
      expect(constraint, '0.1.0');
    });

    test('When its runtime dependencies are read, '
        'Then no adapter, state library, or router package is among them', () {
      // When
      final runtime = dependencies.keys.cast<String>();

      // Then
      expect(runtime.where(_isDevOnly), isEmpty);
    });
  });
}

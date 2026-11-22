// Feature: The interim design system stays movable to its own repository
// (FR-056). Its only runtime dependency is Flutter, and it never references
// Foundations.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('Given the design system package', () {
    test('When its runtime dependencies are read, '
        'Then the only one is flutter', () {
      // Given
      final pubspec =
          loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;

      // When
      final runtime = (pubspec['dependencies'] as YamlMap).keys.toSet();

      // Then
      expect(runtime, {'flutter'});
    });

    test('When the files under lib/ are scanned for directives, '
        'Then none imports, exports, or includes package:foundations', () {
      // Given
      final directive = RegExp(
        r'''^\s*(?:import|export|part)\s+['"]package:foundations/''',
        multiLine: true,
      );
      final files = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      // When
      final offenders = files
          .where((file) => directive.hasMatch(file.readAsStringSync()))
          .map((file) => file.path)
          .toList();

      // Then
      expect(offenders, isEmpty);
    });
  });
}

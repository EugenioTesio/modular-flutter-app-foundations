// Feature: Foundations holds no global state (FR-016, SC-012).
// No `static` field that is not `const`, and no top-level `var`, `late`, or
// mutable typed variable.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _staticMutableField = RegExp(
  r'^\s*static\s+(?!const\b)'
  r'(?:final\b|late\b|var\b|[\w<>?,\[\] ]+\s+\w+\s*(?:=(?!>)|;))',
);
final _topLevelVarOrLate = RegExp(r'^(?:var|late)\b');
final _topLevelTypedMutable = RegExp(
  r'^(?!(?:const|final|typedef|import|export|part|library|abstract|class|'
  r'sealed|base|interface|mixin|enum|extension|return)\b)'
  r'[A-Za-z_][\w<>?,\[\] ]*\s+\w+\s*(?:=(?!>)|;)',
);

/// Returns the offending lines of [source], ignoring comments.
List<String> findGlobalState(String source) => source
    .split('\n')
    .where((line) => !line.trimLeft().startsWith('//'))
    .where(
      (line) =>
          _staticMutableField.hasMatch(line) ||
          _topLevelVarOrLate.hasMatch(line) ||
          _topLevelTypedMutable.hasMatch(line),
    )
    .toList();

void main() {
  group('Given the global-state scanner', () {
    test('When it scans mutable statics and top-level variables, '
        'Then it flags each of them', () {
      // Given
      const offending = [
        '  static int counter = 0;',
        '  static late Foo instance;',
        '  static final cache = <String>{};',
        'var registry = {};',
        'late Foo foo;',
        'int count = 0;',
      ];

      // When
      final results = offending.map(findGlobalState);

      // Then
      for (final result in results) {
        expect(result, hasLength(1));
      }
    });

    test('When it scans constants, methods, getters, declarations, and '
        'comments, Then it flags nothing', () {
      // Given
      const allowed = '''
  static const int ok = 200;
  static Foo create() => Foo();
  static int get value => 1;
const answer = 42;
final class Foo {}
bool isValid(Object? value) => true;
typedef Handler = void Function();
/// static int documented = 0;
''';

      // When
      final result = findGlobalState(allowed);

      // Then
      expect(result, isEmpty);
    });
  });

  group('Given the Dart files under lib/', () {
    test('When each file is scanned, Then none declares global state', () {
      // Given
      final files = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      // When
      final offenders = [
        for (final file in files)
          for (final line in findGlobalState(file.readAsStringSync()))
            '${file.path}: ${line.trim()}',
      ];

      // Then
      expect(offenders, isEmpty);
    });
  });
}

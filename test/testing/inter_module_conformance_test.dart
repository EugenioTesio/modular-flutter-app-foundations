// Feature: The conformance check detects every defect it targets (FR-017,
// SC-003; contracts/conformance.md).
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';
import 'package:foundations/testing.dart';

import '../support/broken_inter_module_communications.dart';
import '../support/reference_inter_module_communication.dart';

/// Cases introduced with User Story 1 (data requests and registration).
const _userStory1Cases = {
  'C01', 'C02', 'C03', 'C04', 'C05', 'C06', //
  'C07', 'C08', 'C09', 'C10', 'C11', 'C17',
};

ConformanceCase _case(String id) =>
    InterModuleConformance.cases.firstWhere((c) => c.id == id);

void main() {
  group('Given the conformance check', () {
    test('When its cases are listed, '
        'Then every User Story 1 case is present exactly once', () {
      // When
      final ids = InterModuleConformance.cases.map((c) => c.id).toList();

      // Then
      expect(ids.toSet(), containsAll(_userStory1Cases));
      expect(ids.toSet(), hasLength(ids.length));
    });
  });

  group('Given the reference implementation', () {
    for (final id in _userStory1Cases) {
      test('When case $id runs, Then it passes', () async {
        // Given
        final conformanceCase = _case(id);

        // When
        final result = await conformanceCase.run(
          ReferenceInterModuleCommunication.new,
        );

        // Then
        expect(result.passed, isTrue, reason: result.message);
      });
    }
  });

  group('Given a deliberately broken implementation', () {
    final targets =
        <String, (InterModuleCommunication Function(), List<String>)>{
          'one that ignores required parameters': (
            ignoresRequiredParameters,
            ['C02', 'C03'],
          ),
          'one that rethrows handler errors': (
            rethrowsHandlerErrors,
            ['C09', 'C10'],
          ),
          'one that leaks exception text': (leaksExceptionText, ['C09']),
          'one that accepts duplicate registrations': (
            acceptsDuplicates,
            ['C11'],
          ),
          'one that shares a registry between types': (
            sharesOneRegistry,
            ['C17'],
          ),
        };

    targets.forEach((description, target) {
      final (create, caseIds) = target;
      for (final id in caseIds) {
        test('When it is $description and case $id runs, '
            'Then the case fails', () async {
          // Given
          final conformanceCase = _case(id);

          // When
          final result = await conformanceCase.run(create);

          // Then
          expect(result.passed, isFalse);
          expect(result.message, isNotNull);
        });
      }
    });
  });
}

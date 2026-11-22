// Feature: Every inter-module data outcome in the runnable example
// (User Story 1; FR-035, SC-008; quickstart.md V4).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';
import 'package:foundations/testing.dart';
import 'package:foundations_example/example_inter_module_communication.dart';
import 'package:foundations_example/main.dart';
import 'package:foundations_example/module_a.dart';
import 'package:foundations_example/module_b.dart';

const _userStory1Cases = {
  'C01', 'C02', 'C03', 'C04', 'C05', 'C06', //
  'C07', 'C08', 'C09', 'C10', 'C11', 'C17',
};

/// Expected status and error code for each scenario, by label.
const _expected = {
  'Details for id 123': (200, null),
  'Details without an id': (400, 'missing_required_parameters'),
  'Details with an empty id': (400, 'invalid_id'),
  'Details for an unknown id': (404, 'details_not_found'),
  'A module that is not installed': (404, 'endpoint_not_registered'),
  'Details while signed out': (400, 'unauthenticated'),
  'Details without permission': (400, 'forbidden'),
  'Details when Module B fails': (500, null),
};

void main() {
  group('Given the example communication implementation', () {
    for (final conformanceCase in InterModuleConformance.cases.where(
      (c) => _userStory1Cases.contains(c.id),
    )) {
      test('When conformance case ${conformanceCase.id} runs, '
          'Then it passes', () async {
        // When
        final result = await conformanceCase.run(
          ExampleInterModuleCommunication.new,
        );

        // Then
        expect(result.passed, isTrue, reason: result.message);
      });
    }
  });

  group('Given a host with Module B registered', () {
    late ExampleInterModuleCommunication communication;
    late ModuleBAccess access;

    setUp(() {
      access = ModuleBAccess.granted;
      communication = ExampleInterModuleCommunication()
        ..registerProviders(
          data: [ModuleBDetailsProvider(access: () => access)],
        );
    });

    for (final scenario in dataScenarios) {
      final (status, code) = _expected[scenario.label]!;
      test('When Module A runs "${scenario.label}", '
          'Then it receives $status ${code ?? 'with no error code'}', () async {
        // Given
        access = scenario.access;

        // When
        final response = await communication.request(
          endpoint: scenario.endpoint,
        );

        // Then
        expect(response.statusCode, status);
        expect(response.errorCode, code);
        expect(response.data == null, status != 200);
      });
    }

    test(
      'When every scenario runs, '
      'Then each outcome gets a distinct message from status and code alone',
      () async {
        // When
        final messages = <String>[];
        for (final scenario in dataScenarios) {
          access = scenario.access;
          messages.add(
            describeOutcome(
              await communication.request(endpoint: scenario.endpoint),
            ),
          );
        }

        // Then
        expect(messages.toSet(), hasLength(dataScenarios.length));
      },
    );
  });

  group('Given the example app', () {
    testWidgets('When it starts, '
        'Then Module A shows one outcome row per scenario', (tester) async {
      // Given
      final app = FoundationsExampleApp.create();

      // When
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(ListTile), findsNWidgets(dataScenarios.length));
      expect(find.textContaining('Loaded: Example details'), findsOneWidget);
      expect(
        find.textContaining('This feature is unavailable'),
        findsOneWidget,
      );
    });
  });
}

// Feature: Every inter-module data outcome in the runnable example:
// Transfers checks a card through Cards (User Story 1; FR-035, SC-008;
// quickstart.md V4).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';
import 'package:foundations/testing.dart';
import 'package:foundations_example/host/example_host.dart';
import 'package:foundations_example/host/example_inter_module_communication.dart';
import 'package:foundations_example/host/example_services.dart';
import 'package:foundations_example/main.dart';
import 'package:foundations_example/cards.dart';
import 'package:foundations_example/transfers.dart';
import 'package:switchable_state_riverpod/switchable_state_riverpod.dart';

const _userStory1Cases = {
  'C01', 'C02', 'C03', 'C04', 'C05', 'C06', //
  'C07', 'C08', 'C09', 'C10', 'C11', 'C17',
};

/// Expected status and error code for each scenario, by label.
const _expected = {
  'Pay from card-123': (200, null),
  'Pay without choosing a card': (400, 'missing_required_parameters'),
  'Pay from an empty card id': (400, 'invalid_card_id'),
  'Pay from an unknown card': (404, 'card_not_found'),
  'Pay from a loan, a module that is not installed': (
    404,
    'endpoint_not_registered',
  ),
  'Pay from card-123 while signed out': (400, 'unauthenticated'),
  'Pay from card-123 without permission': (400, 'forbidden'),
  'Pay while Cards fails': (500, null),
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

  group('Given a host that started Cards through its context', () {
    late ExampleSessionContext session;
    late InterModuleCommunication communication;

    setUp(() async {
      session = ExampleSessionContext(DemoSessions.signedIn);
      final host = ExampleHost(session: session, microApps: [CardsMicroApp()]);
      await host.start();
      communication = host.communication;
    });

    for (final scenario in dataScenarios) {
      final (status, code) = _expected[scenario.label]!;
      test('When Transfers runs "${scenario.label}", '
          'Then it receives $status ${code ?? 'with no error code'}', () async {
        // Given
        session.set(scenario.session);

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
          session.set(scenario.session);
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
    testWidgets('When the user taps Transfers\' shortcut on Home, '
        'Then Transfers shows one outcome row per scenario', (tester) async {
      // Given
      await tester.pumpWidget(const FoundationsExampleApp());
      await tester.pumpAndSettle();

      // When
      await tester.tap(find.text('Transfers'));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(DsListTile), findsNWidgets(dataScenarios.length));
      expect(find.textContaining('Pays from card •••• 4821'), findsOneWidget);
      expect(
        find.textContaining('This payment method is unavailable'),
        findsOneWidget,
      );
    });

    testWidgets('When it starts under the root StateScope on a dark device, '
        'Then it renders the design system dark theme', (tester) async {
      // Given
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      // When
      await tester.pumpWidget(
        StateScope(
          adapter: const RiverpodStateAdapter(),
          child: const FoundationsExampleApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Then
      final context = tester.element(find.byType(DsPageScaffold));
      expect(
        context.dsColors.background,
        DsTheme.dark().extension<DsColors>()!.background,
      );
      expect(find.text('Home'), findsOneWidget);
    });
  });
}

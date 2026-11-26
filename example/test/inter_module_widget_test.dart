// Feature: Home embeds UI that Cards and Transfers own, with predictable
// fallbacks
// (User Story 5; FR-035, SC-008; quickstart.md V4, home-banner rows).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';
import 'package:foundations/testing.dart';
import 'package:foundations_example/cards.dart';
import 'package:foundations_example/home.dart';
import 'package:foundations_example/host/example_host.dart';
import 'package:foundations_example/host/example_inter_module_communication.dart';
import 'package:foundations_example/host/example_services.dart';
import 'package:foundations_example/main.dart';
import 'package:foundations_example/transfers.dart';

const _userStory5Cases = {'C12', 'C13', 'C14', 'C15', 'C16'};

/// Starts Home, plus Cards and Transfers when installed, the way the example
/// does.
Future<ExampleHost> _startHost({
  bool cardsInstalled = true,
  bool transfersInstalled = true,
  Map<String, Object?> apiResponses = FoundationsExampleApp.defaultApiResponses,
}) async {
  final session = ExampleSessionContext(DemoSessions.signedIn);
  final host = ExampleHost(
    session: session,
    apiResponses: apiResponses,
    microApps: [
      HomeMicroApp(),
      if (transfersInstalled) TransfersMicroApp(prepareScenario: session.set),
      if (cardsInstalled) CardsMicroApp(),
    ],
  );
  await host.start();
  return host;
}

Future<void> _pumpHome(WidgetTester tester, ExampleHost host) =>
    tester.pumpWidget(
      MaterialApp(
        theme: DsTheme.light(),
        home: HomeScreen(communication: host.communication),
      ),
    );

void main() {
  group('Given the example communication implementation', () {
    for (final conformanceCase in InterModuleConformance.cases.where(
      (c) => _userStory5Cases.contains(c.id),
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
    test('When Home asks for the banner with no parameters, '
        'Then it receives 200 and the banner, synchronously', () async {
      // Given
      final host = await _startHost();

      // When
      final response = host.communication.getWidget(
        endpoint: HomeScreen.cardsBanner,
      );

      // Then
      expect(response.statusCode, InterModuleStatusCode.ok);
      expect(response.data, isA<CardsHomeBanner>());
    });

    testWidgets('When Home places the banner, Then the banner loads the '
        'primary card through Cards\' own API client', (tester) async {
      // Given
      final host = await _startHost();
      await _pumpHome(tester, host);
      // Home's list reads the banner as one node: "Your card, Loading card
      // details".
      expect(
        find.bySemanticsLabel(RegExp('Loading card details')),
        findsOneWidget,
      );

      // When
      await tester.pumpAndSettle();

      // Then
      expect(find.text('Card •••• 4821'), findsOneWidget);
      expect(find.text('Available credit: 2,500'), findsOneWidget);
    });

    testWidgets('When the banner fails to load its own data, '
        'Then the banner shows its own error and Home is unaffected', (
      tester,
    ) async {
      // Given: the backend has no answer for the primary card.
      final host = await _startHost(apiResponses: const {});

      // When
      await _pumpHome(tester, host);
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(CardsHomeBanner), findsOneWidget);
      expect(
        find.text('Card details are unavailable right now.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Given a host without Cards', () {
    test('When Home asks for the banner, '
        'Then it receives 404 endpoint_not_registered', () async {
      // Given
      final host = await _startHost(cardsInstalled: false);

      // When
      final response = host.communication.getWidget(
        endpoint: HomeScreen.cardsBanner,
      );

      // Then
      expect(response.statusCode, InterModuleStatusCode.notFound);
      expect(response.errorCode, InterModuleErrorCode.endpointNotRegistered);
    });

    testWidgets('When Home is shown, Then it renders its fallback', (
      tester,
    ) async {
      // Given
      final host = await _startHost(cardsInstalled: false);

      // When
      await _pumpHome(tester, host);

      // Then
      expect(find.byType(CardsHomeBanner), findsNothing);
      expect(find.text('Cards is not available'), findsOneWidget);
    });
  });

  group('Given a host that started Transfers through its context', () {
    test('When Home asks for the shortcut with no parameters, '
        'Then it receives 200 and the shortcut, synchronously', () async {
      // Given
      final host = await _startHost();

      // When
      final response = host.communication.getWidget(
        endpoint: HomeScreen.transfersShortcut,
      );

      // Then
      expect(response.statusCode, InterModuleStatusCode.ok);
      expect(response.data, isA<DsListTile>());
    });
  });

  group('Given a host without Transfers', () {
    testWidgets('When Home is shown, '
        'Then it leaves the shortcut out and still shows the banner', (
      tester,
    ) async {
      // Given
      final host = await _startHost(transfersInstalled: false);

      // When
      await _pumpHome(tester, host);
      await tester.pumpAndSettle();

      // Then
      expect(find.text('Transfers'), findsNothing);
      expect(find.text('Card •••• 4821'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Given the example app', () {
    testWidgets('When "Cards installed" is switched off and on, '
        'Then Home swaps between the fallback and the banner', (tester) async {
      // Given
      await tester.pumpWidget(const FoundationsExampleApp());
      await tester.pumpAndSettle();
      expect(find.text('Card •••• 4821'), findsOneWidget);

      // When
      await tester.tap(find.text('Cards installed'));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(CardsHomeBanner), findsNothing);
      expect(find.text('Cards is not available'), findsOneWidget);

      // When
      await tester.tap(find.text('Cards installed'));
      await tester.pumpAndSettle();

      // Then
      expect(find.text('Card •••• 4821'), findsOneWidget);
    });
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:foundations/foundations.dart';

/// Transfers as a micro app. It owns:
///
/// * The `/transfers` screen, which checks the card a transfer pays from. It
///   asks Cards through its context's communication and never imports Cards'
///   code.
/// * `/transfers/v1/home-shortcut`, a shortcut other micro apps, such as
///   Home, place in their own screens. Opening the screen is Transfers'
///   business: the shortcut navigates through Transfers' own navigator.
final class TransfersMicroApp implements MicroApp {
  /// Creates Transfers.
  ///
  /// [prepareScenario] is a demo-only hook: the host applies the session a
  /// scenario needs. A real micro app has no such hook.
  TransfersMicroApp({required this.prepareScenario});

  /// Applies a scenario's session before its call. Demo only.
  final void Function(SessionState session) prepareScenario;

  late final MicroAppContext _context;

  /// Path of Transfers' screen.
  static const path = '/transfers';

  @override
  String get id => 'transfers';

  @override
  Set<String> get storedKeys => const {};

  @override
  Future<void> initialize(MicroAppContext context) async => _context = context;

  @override
  List<MicroAppRouteNode> get routes => [
    MicroAppRoute(
      path: path,
      builder: (context, parameters, body) => DsPageScaffold(
        title: 'Transfers',
        body: SingleChildScrollView(
          child: TransfersScreen(
            communication: _context.communication,
            prepareScenario: prepareScenario,
          ),
        ),
      ),
    ),
  ];

  @override
  List<LocalizationsDelegate<Object?>> get localizationsDelegates => const [];

  @override
  List<DataEndpointProvider> get dataEndpoints => const [];

  @override
  List<WidgetEndpointProvider> get widgetEndpoints => [
    TransfersHomeShortcutProvider(navigator: _context.navigator),
  ];

  @override
  Future<void> dispose() async {}
}

/// Provides `/transfers/v1/home-shortcut`: a tile that opens Transfers'
/// screen. Callers send no parameters.
class TransfersHomeShortcutProvider implements WidgetEndpointProvider {
  /// Creates the provider over Transfers' [navigator].
  const TransfersHomeShortcutProvider({required this.navigator});

  /// Transfers' navigator.
  final AppNavigator navigator;

  @override
  InterModuleEndpoint get endpoint =>
      const InterModuleEndpoint(url: '/transfers/v1/home-shortcut');

  @override
  InterModuleCommunicationResponse<Widget> build(
    Map<String, Object?> parameters,
  ) => InterModuleCommunicationResponse.success(
    DsListTile(
      title: 'Transfers',
      subtitle: 'Check the card a transfer pays from',
      leading: const Icon(Icons.swap_horiz),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => unawaited(navigator.push(TransfersMicroApp.path)),
    ),
  );
}

/// The sessions the demo scenarios run under. Transfers only knows them as
/// Foundations [SessionState] values; the host applies them.
abstract final class DemoSessions {
  /// Signed in with the role Cards requires for card details.
  static const signedIn = Authenticated(
    UserIdentity(
      userId: 'demo-user',
      customProperties: {
        'roles': ['cards.details.reader'],
      },
    ),
  );

  /// Signed out.
  static const signedOut = Unauthenticated();

  /// Signed in, without Cards' role.
  static const withoutPermission = Authenticated(
    UserIdentity(userId: 'demo-user'),
  );
}

/// One data call that Transfers makes, and the session it needs.
class DataScenario {
  /// Creates a scenario.
  const DataScenario({
    required this.label,
    required this.endpoint,
    this.session = DemoSessions.signedIn,
  });

  /// A short description shown in the demo.
  final String label;

  /// The call Transfers makes.
  final InterModuleEndpoint endpoint;

  /// The session while the call runs.
  final SessionState session;
}

const _details = '/cards/v1/details';

/// Every data outcome from the quickstart (V4), in display order.
const dataScenarios = [
  DataScenario(
    label: 'Pay from card-123',
    endpoint: InterModuleEndpoint(
      url: _details,
      parameters: {'cardId': 'card-123'},
      traceName: 'transfers.card_details',
    ),
  ),
  DataScenario(
    label: 'Pay without choosing a card',
    endpoint: InterModuleEndpoint(url: _details),
  ),
  DataScenario(
    label: 'Pay from an empty card id',
    endpoint: InterModuleEndpoint(url: _details, parameters: {'cardId': ''}),
  ),
  DataScenario(
    label: 'Pay from an unknown card',
    endpoint: InterModuleEndpoint(
      url: _details,
      parameters: {'cardId': 'card-999'},
    ),
  ),
  DataScenario(
    label: 'Pay from a loan, a module that is not installed',
    endpoint: InterModuleEndpoint(url: '/loans/v1/summary'),
  ),
  DataScenario(
    label: 'Pay from card-123 while signed out',
    endpoint: InterModuleEndpoint(
      url: _details,
      parameters: {'cardId': 'card-123'},
    ),
    session: DemoSessions.signedOut,
  ),
  DataScenario(
    label: 'Pay from card-123 without permission',
    endpoint: InterModuleEndpoint(
      url: _details,
      parameters: {'cardId': 'card-123'},
    ),
    session: DemoSessions.withoutPermission,
  ),
  DataScenario(
    label: 'Pay while Cards fails',
    endpoint: InterModuleEndpoint(
      url: _details,
      parameters: {'cardId': 'boom'},
    ),
  ),
];

/// Turns a response into the message Transfers shows, using only the status
/// and the error code (SC-008).
String describeOutcome(
  InterModuleCommunicationResponse<Map<String, Object?>> response,
) {
  final maskedNumber = response.data?['maskedNumber'];
  return switch ((response.statusCode, response.errorCode)) {
    (200, _) =>
      maskedNumber is String
          ? 'Pays from card $maskedNumber'
          : 'Unexpected response format',
    (400, InterModuleErrorCode.missingRequiredParameters) =>
      'Choose a card to pay from.',
    (400, 'invalid_card_id') => 'The card is not valid.',
    (400, InterModuleErrorCode.unauthenticated) =>
      'Sign in to pay from a card.',
    (400, InterModuleErrorCode.forbidden) =>
      'You are not allowed to pay from this card.',
    (404, InterModuleErrorCode.endpointNotRegistered) =>
      'This payment method is unavailable in this application.',
    (404, _) => 'The card was not found.',
    _ => 'Unable to check the card. Please try again.',
  };
}

/// Transfers' demo content: one row per data scenario.
class TransfersScreen extends StatefulWidget {
  /// Creates the content.
  const TransfersScreen({
    super.key,
    required this.communication,
    required this.prepareScenario,
  });

  /// The inter-module communication contract.
  final InterModuleCommunication communication;

  /// Applies each scenario's session before its call. Demo only.
  final void Function(SessionState session) prepareScenario;

  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen> {
  late final Future<List<String>> _outcomes = _runAll();

  Future<List<String>> _runAll() async {
    final outcomes = <String>[];
    for (final scenario in dataScenarios) {
      widget.prepareScenario(scenario.session);
      final response = await widget.communication.request(
        endpoint: scenario.endpoint,
      );
      final status = '${response.statusCode} ${response.errorCode ?? ''}'
          .trim();
      outcomes.add('$status · ${describeOutcome(response)}');
    }
    widget.prepareScenario(DemoSessions.signedIn);
    return outcomes;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _outcomes,
      builder: (context, snapshot) {
        final outcomes = snapshot.data;
        if (outcomes == null) {
          return const Center(
            child: DsLoadingIndicator(semanticsLabel: 'Checking the cards'),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < dataScenarios.length; i++)
              DsListTile(title: dataScenarios[i].label, subtitle: outcomes[i]),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:foundations/foundations.dart';

import 'module_b.dart';

/// One data call that Module A makes, and the setup it needs.
class DataScenario {
  /// Creates a scenario.
  const DataScenario({
    required this.label,
    required this.endpoint,
    this.access = ModuleBAccess.granted,
  });

  /// A short description shown in the demo.
  final String label;

  /// The call Module A makes.
  final InterModuleEndpoint endpoint;

  /// The user's access while the call runs.
  final ModuleBAccess access;
}

const _details = '/module-b/v1/details';

/// Every data outcome from the quickstart (V4), in display order.
const dataScenarios = [
  DataScenario(
    label: 'Details for id 123',
    endpoint: InterModuleEndpoint(
      url: _details,
      parameters: {'id': '123'},
      traceName: 'module_a.details',
    ),
  ),
  DataScenario(
    label: 'Details without an id',
    endpoint: InterModuleEndpoint(url: _details),
  ),
  DataScenario(
    label: 'Details with an empty id',
    endpoint: InterModuleEndpoint(url: _details, parameters: {'id': ''}),
  ),
  DataScenario(
    label: 'Details for an unknown id',
    endpoint: InterModuleEndpoint(url: _details, parameters: {'id': '999'}),
  ),
  DataScenario(
    label: 'A module that is not installed',
    endpoint: InterModuleEndpoint(url: '/module-c/v1/summary'),
  ),
  DataScenario(
    label: 'Details while signed out',
    endpoint: InterModuleEndpoint(url: _details, parameters: {'id': '123'}),
    access: ModuleBAccess.signedOut,
  ),
  DataScenario(
    label: 'Details without permission',
    endpoint: InterModuleEndpoint(url: _details, parameters: {'id': '123'}),
    access: ModuleBAccess.forbidden,
  ),
  DataScenario(
    label: 'Details when Module B fails',
    endpoint: InterModuleEndpoint(url: _details, parameters: {'id': 'boom'}),
  ),
];

/// Turns a response into the message Module A shows, using only the status
/// and the error code (SC-008).
String describeOutcome(
  InterModuleCommunicationResponse<Map<String, Object?>> response,
) {
  final name = response.data?['name'];
  return switch ((response.statusCode, response.errorCode)) {
    (200, _) => name is String ? 'Loaded: $name' : 'Unexpected response format',
    (400, InterModuleErrorCode.missingRequiredParameters) =>
      'A valid id is required to load details.',
    (400, 'invalid_id') => 'The id is not valid.',
    (400, InterModuleErrorCode.unauthenticated) => 'Sign in to see details.',
    (400, InterModuleErrorCode.forbidden) =>
      'You are not allowed to see these details.',
    (404, InterModuleErrorCode.endpointNotRegistered) =>
      'This feature is unavailable in this application.',
    (404, _) => 'The requested details were not found.',
    _ => 'Unable to load details. Please try again.',
  };
}

/// Module A's demo screen: one row per data scenario.
///
/// Module A imports only Foundations; it never imports Module B's code.
class ModuleAScreen extends StatefulWidget {
  /// Creates the screen.
  const ModuleAScreen({
    super.key,
    required this.communication,
    required this.setAccess,
  });

  /// The inter-module communication contract.
  final InterModuleCommunication communication;

  /// Sets the user's access before each call. Part of the demo setup only.
  final void Function(ModuleBAccess access) setAccess;

  @override
  State<ModuleAScreen> createState() => _ModuleAScreenState();
}

class _ModuleAScreenState extends State<ModuleAScreen> {
  late final Future<List<String>> _outcomes = _runAll();

  Future<List<String>> _runAll() async {
    final outcomes = <String>[];
    for (final scenario in dataScenarios) {
      widget.setAccess(scenario.access);
      final response = await widget.communication.request(
        endpoint: scenario.endpoint,
      );
      final status = '${response.statusCode} ${response.errorCode ?? ''}'
          .trim();
      outcomes.add('$status · ${describeOutcome(response)}');
    }
    widget.setAccess(ModuleBAccess.granted);
    return outcomes;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _outcomes,
      builder: (context, snapshot) {
        final outcomes = snapshot.data;
        if (outcomes == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          children: [
            for (var i = 0; i < dataScenarios.length; i++)
              ListTile(
                title: Text(dataScenarios[i].label),
                subtitle: Text(outcomes[i]),
              ),
          ],
        );
      },
    );
  }
}

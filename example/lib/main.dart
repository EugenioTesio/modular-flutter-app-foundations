import 'package:flutter/material.dart';
import 'package:foundations/foundations.dart';

import 'example_inter_module_communication.dart';
import 'module_a.dart';
import 'module_b.dart';

void main() => runApp(FoundationsExampleApp.create());

/// Example app for the Foundations contracts.
///
/// It plays the host: it creates the communication implementation, registers
/// Module B's providers in bulk, and shows Module A's calls.
class FoundationsExampleApp extends StatelessWidget {
  /// Creates the app with an already wired [communication].
  const FoundationsExampleApp({
    super.key,
    required this.communication,
    required this.setAccess,
  });

  /// Wires the example the way a host would.
  factory FoundationsExampleApp.create() {
    var access = ModuleBAccess.granted;
    final communication = ExampleInterModuleCommunication()
      ..registerProviders(data: [ModuleBDetailsProvider(access: () => access)]);
    return FoundationsExampleApp(
      communication: communication,
      setAccess: (value) => access = value,
    );
  }

  /// The inter-module communication implementation.
  final InterModuleCommunication communication;

  /// Sets Module B's simulated access.
  final void Function(ModuleBAccess access) setAccess;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foundations example',
      home: Scaffold(
        appBar: AppBar(title: const Text('Module A → Module B')),
        body: ModuleAScreen(communication: communication, setAccess: setAccess),
      ),
    );
  }
}

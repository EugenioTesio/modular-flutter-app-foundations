import 'package:flutter/material.dart';

void main() => runApp(const FoundationsExampleApp());

/// Example app for the Foundations contracts.
///
/// Later phases add the inter-module data demo (Module A and B) and the
/// federated Home with the Cards banner.
class FoundationsExampleApp extends StatelessWidget {
  /// Creates the example app.
  const FoundationsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Foundations example',
      home: Scaffold(
        body: Center(child: Text('Foundations example')),
      ),
    );
  }
}

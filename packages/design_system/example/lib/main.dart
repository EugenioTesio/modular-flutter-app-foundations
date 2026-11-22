import 'package:flutter/material.dart';

void main() => runApp(const DesignSystemGalleryApp());

/// Gallery for the interim design system.
///
/// A later phase (T079) shows every component in every state, with light/dark
/// and brand toggles.
class DesignSystemGalleryApp extends StatelessWidget {
  /// Creates the gallery app.
  const DesignSystemGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Design system gallery',
      home: Scaffold(
        body: Center(child: Text('Design system gallery')),
      ),
    );
  }
}

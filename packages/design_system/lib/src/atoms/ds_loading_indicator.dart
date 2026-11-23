/// @docImport '../tokens/ds_colors.dart';
/// @docImport 'ds_button.dart';
library;

import 'package:flutter/material.dart';

import '../theme/ds_theme_context.dart';

/// Widget that shows that content is loading, in the action color.
///
/// Use this while a screen or section waits for data, for example in place of
/// a list until the first page arrives.
///
/// This is **not** for a button that is busy: set [DsButton.isLoading]
/// instead, so the button keeps its size and label.
///
/// Built-in: the spinner uses [DsColors.actionPrimary] and is announced to
/// screen readers with [semanticsLabel]. It animates until it is removed.
///
/// Usage from a micro app:
/// ```dart
/// if (accounts == null) {
///   return const Center(
///     child: DsLoadingIndicator(semanticsLabel: 'Loading accounts'),
///   );
/// }
/// ```
final class DsLoadingIndicator extends StatelessWidget {
  /// Creates a loading indicator.
  ///
  /// Parameters:
  /// * [semanticsLabel] - What is loading, announced to screen readers, such
  ///   as "Loading accounts". Localize it.
  /// * [size] - Diameter in logical pixels. Defaults to 24.
  const DsLoadingIndicator({
    super.key,
    required this.semanticsLabel,
    this.size = 24,
  });

  /// What is loading, announced to screen readers.
  final String semanticsLabel;

  /// Diameter in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(
        semanticsLabel: semanticsLabel,
        strokeWidth: size / 8,
        color: context.dsColors.actionPrimary,
      ),
    );
  }
}

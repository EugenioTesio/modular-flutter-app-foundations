import 'package:flutter/painting.dart';

/// Helper that measures and enforces WCAG contrast between colors when a
/// theme is built.
///
/// This is internal to the design system and is not exported.
abstract final class DsContrast {
  /// Returns the WCAG contrast ratio between [a] and [b], from 1 to 21.
  ///
  /// Parameters:
  /// * [a] - One color.
  /// * [b] - The other color. The order does not matter.
  static double ratio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final lighter = la > lb ? la : lb;
    final darker = la > lb ? lb : la;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Returns [color], moved toward [towards] in small steps until it reaches
  /// [minimum] contrast against every color in [against].
  ///
  /// Parameters:
  /// * [color] - The color to keep as close to the original as possible.
  /// * [against] - The colors it must contrast with.
  /// * [minimum] - The contrast ratio to reach.
  /// * [towards] - The color to move toward, usually the end opposite to
  ///   [against].
  ///
  /// Returns [color] unchanged when it already reaches [minimum], and
  /// [towards] when no step in between does.
  static Color ensure(
    Color color, {
    required List<Color> against,
    required double minimum,
    required Color towards,
  }) {
    const steps = 20;
    for (var step = 0; step <= steps; step++) {
      final candidate = Color.lerp(color, towards, step / steps)!;
      if (against.every((other) => ratio(candidate, other) >= minimum)) {
        return candidate;
      }
    }
    return towards;
  }

  /// Returns whichever of [light] and [dark] contrasts more with
  /// [background].
  ///
  /// Parameters:
  /// * [background] - The color the text sits on.
  /// * [light] - The light text candidate.
  /// * [dark] - The dark text candidate.
  static Color bestText(
    Color background, {
    required Color light,
    required Color dark,
  }) => ratio(light, background) >= ratio(dark, background) ? light : dark;
}

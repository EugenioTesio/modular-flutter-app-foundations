/// @docImport '../theme/ds_brand.dart';
/// @docImport '../theme/ds_theme.dart';
/// @docImport 'ds_colors.dart';
library;

import 'package:flutter/painting.dart';

/// Primitive color tokens: the fixed base colors every theme is built from.
///
/// Use this only when you build a theme. Components and micro app screens
/// read the semantic roles in [DsColors] instead, so a theme or brand change
/// restyles them without code changes.
///
/// This is **not** the brand color: that comes from [DsBrand.primary], and
/// [DsTheme] derives the action and information roles from it.
///
/// Built-in: [DsTheme.light] and [DsTheme.dark] map these values onto the
/// [DsColors] roles.
///
/// Scales:
/// * Neutral, from [neutral0] (white) to [neutral900] (near black), for
///   backgrounds, surfaces, borders, and text.
/// * Success, warning, and error, each with a light tint (`100`), a mid tone
///   (`500`), and a dark tone (`700`).
///
/// Usage from a theme:
/// ```dart
/// final border = BorderSide(color: DsPalette.neutral300);
/// ```
abstract final class DsPalette {
  /// White.
  static const Color neutral0 = Color(0xFFFFFFFF);

  /// Off-white, the lightest tint.
  static const Color neutral50 = Color(0xFFF7F8FA);

  /// Very light gray.
  static const Color neutral100 = Color(0xFFEEF0F3);

  /// Light gray.
  static const Color neutral200 = Color(0xFFDDE1E6);

  /// Light mid gray.
  static const Color neutral300 = Color(0xFFC3C8CF);

  /// Mid gray.
  static const Color neutral400 = Color(0xFF9AA1AB);

  /// Dark mid gray.
  static const Color neutral500 = Color(0xFF6E7681);

  /// Dark gray.
  static const Color neutral600 = Color(0xFF545B66);

  /// Darker gray.
  static const Color neutral700 = Color(0xFF3D434C);

  /// Very dark gray.
  static const Color neutral800 = Color(0xFF272C33);

  /// Near black, the darkest tone.
  static const Color neutral900 = Color(0xFF14171C);

  /// Light success tint.
  static const Color success100 = Color(0xFFE3F4E8);

  /// Mid success tone.
  static const Color success500 = Color(0xFF2E9E57);

  /// Dark success tone.
  static const Color success700 = Color(0xFF1B6B39);

  /// Light warning tint.
  static const Color warning100 = Color(0xFFFDF1DC);

  /// Mid warning tone.
  static const Color warning500 = Color(0xFFE09B1A);

  /// Dark warning tone.
  static const Color warning700 = Color(0xFF7A4F00);

  /// Light error tint.
  static const Color error100 = Color(0xFFFCE6E6);

  /// Mid error tone.
  static const Color error500 = Color(0xFFD93838);

  /// Dark error tone.
  static const Color error700 = Color(0xFFA31F1F);
}

/// @docImport '../tokens/ds_colors.dart';
/// @docImport '../tokens/ds_typography.dart';
/// @docImport 'ds_theme.dart';
library;

import 'package:flutter/widgets.dart';

/// Value that holds the application's single brand configuration.
///
/// Use this when the host builds its themes: pass the same brand to
/// [DsTheme.light] and [DsTheme.dark], and every component follows it.
///
/// This is **not** a set of colors to use in screens: screens read the roles
/// in [DsColors], which the themes derive from this brand.
///
/// Built-in: the themes derive [DsColors.actionPrimary],
/// [DsColors.actionPrimaryPressed], [DsColors.focus], [DsColors.textOnAction],
/// and the information roles from [primary], and set the font family of every
/// [DsTypography] style from [fontFamily].
///
/// Rules:
/// * When [primary] is too light or too dark to reach 4.5:1 against the
///   theme's background, the theme moves it toward the contrasting end until
///   it does. A brand color with enough contrast is used unchanged.
/// * [DsColors.textOnAction] is light or dark text, whichever reaches 4.5:1 on the
///   action color.
///
/// Usage from a host:
/// ```dart
/// const brand = DsBrand(primary: Color(0xFF0B6E4F), fontFamily: 'Inter');
///
/// MaterialApp(
///   theme: DsTheme.light(brand: brand),
///   darkTheme: DsTheme.dark(brand: brand),
///   home: const HomeScreen(),
/// );
/// ```
@immutable
final class DsBrand {
  /// Creates a brand configuration.
  ///
  /// Parameters:
  /// * [primary] - The brand color that the action and focus roles derive
  ///   from.
  /// * [fontFamily] - Optional font family for all text. The host app
  ///   declares the font in its own assets. When null, or when the font is
  ///   not bundled, text uses the platform font.
  const DsBrand({required this.primary, this.fontFamily});

  /// The default brand: a blue primary color and the platform font.
  static const DsBrand standard = DsBrand(primary: Color(0xFF1F5FD1));

  /// Brand color that the action and focus roles derive from.
  final Color primary;

  /// Optional font family for all text; null means the platform font.
  final String? fontFamily;

  @override
  bool operator ==(Object other) =>
      other is DsBrand &&
      other.primary == primary &&
      other.fontFamily == fontFamily;

  @override
  int get hashCode => Object.hash(primary, fontFamily);

  @override
  String toString() => 'DsBrand(primary: $primary, fontFamily: $fontFamily)';
}

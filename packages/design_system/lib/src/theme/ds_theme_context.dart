/// @docImport 'ds_theme.dart';
library;

import 'package:flutter/material.dart';

import '../tokens/ds_colors.dart';
import '../tokens/ds_typography.dart';

/// Extension that reads the design system's semantic tokens from the
/// nearest [Theme].
///
/// Use this in every widget that needs a color or text style:
/// `context.dsColors` and `context.dsTypography`.
///
/// This is **not** a way to change the theme: the host sets it once with
/// [DsTheme.light] and [DsTheme.dark].
///
/// Built-in: the getters read the [ThemeExtension]s that [DsTheme] installs,
/// and register a dependency on the theme, so the widget rebuilds when the
/// theme or brand changes.
///
/// Usage from a micro app:
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   final colors = context.dsColors;
///   return ColoredBox(
///     color: colors.surface,
///     child: Text(
///       'Balance',
///       style: context.dsTypography.title.copyWith(color: colors.textPrimary),
///     ),
///   );
/// }
/// ```
extension DsThemeContext on BuildContext {
  /// Color roles of the active theme.
  ///
  /// Throws a [FlutterError] when the theme was not built with [DsTheme],
  /// which is a wiring mistake in the host.
  DsColors get dsColors =>
      Theme.of(this).extension<DsColors>() ?? (throw _missing('DsColors'));

  /// Text styles of the active theme.
  ///
  /// Throws a [FlutterError] when the theme was not built with [DsTheme],
  /// which is a wiring mistake in the host.
  DsTypography get dsTypography =>
      Theme.of(this).extension<DsTypography>() ??
      (throw _missing('DsTypography'));

  FlutterError _missing(String type) => FlutterError.fromParts([
    ErrorSummary('No $type found in the current Theme.'),
    ErrorHint(
      'Build the app theme with DsTheme.light() or DsTheme.dark(), for '
      'example MaterialApp(theme: DsTheme.light(), darkTheme: '
      'DsTheme.dark()).',
    ),
  ]);
}

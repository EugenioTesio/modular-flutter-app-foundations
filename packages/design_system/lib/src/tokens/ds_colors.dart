/// @docImport 'package:flutter/material.dart';
/// @docImport '../theme/ds_brand.dart';
/// @docImport '../theme/ds_theme.dart';
/// @docImport '../theme/ds_theme_context.dart';
/// @docImport 'ds_palette.dart';
library;

import 'package:flutter/material.dart';

/// Semantic color roles, resolved for the active theme and brand.
///
/// Use this for every color in a screen, through `context.dsColors`: text in
/// [textPrimary] or [textSecondary], cards on [surface], and so on. A role
/// names what the color is for, so dark mode and brand changes restyle the
/// screen with no code change.
///
/// This is **not** the palette: [DsPalette] holds the fixed base colors, and
/// only themes read it.
///
/// Built-in: [DsTheme.light] and [DsTheme.dark] create it from a [DsBrand]
/// and install it as a [ThemeExtension] of the [ThemeData].
///
/// Contrast guarantees, in both themes:
/// * [textPrimary] and [textSecondary] reach at least 4.5:1 on [background],
///   [surface], and [surfaceVariant].
/// * [textOnAction] reaches at least 4.5:1 on [actionPrimary] and
///   [actionPrimaryPressed].
/// * [actionPrimary] reaches at least 4.5:1 on [background] and [surface], so
///   it also works as text color. That is above the 3:1 interface minimum.
/// * Each message foreground reaches at least 4.5:1 on its background, and
///   [errorForeground] also on [background] and [surface].
/// * [textDisabled] has no minimum: disabled controls are exempt.
///
/// Usage from a micro app:
/// ```dart
/// final colors = context.dsColors;
/// return Text(
///   'Last updated today',
///   style: context.dsTypography.caption.copyWith(color: colors.textSecondary),
/// );
/// ```
@immutable
final class DsColors extends ThemeExtension<DsColors> {
  /// Creates a set of color roles. Themes call this; screens read the roles
  /// through `context.dsColors` instead.
  ///
  /// Parameters:
  /// * [background] - Background color of a page.
  /// * [surface] - Color of raised content on the page, such as cards, fields, and sheets.
  /// * [surfaceVariant] - Color of secondary surfaces, such as a selected row or a grouped area.
  /// * [border] - Color of borders and dividers.
  /// * [textPrimary] - Color of primary text on [background], [surface], and [surfaceVariant].
  /// * [textSecondary] - Color of supporting text, such as subtitles, hints, and helper text, on [background], [surface], and [surfaceVariant].
  /// * [textDisabled] - Color of text and icons in disabled controls.
  /// * [textOnAction] - Color of text and icons on [actionPrimary] and [actionPrimaryPressed].
  /// * [actionPrimary] - Color of the primary action: the primary button fill, and the text of secondary and tertiary buttons.
  /// * [actionPrimaryPressed] - Color of the primary action while it is pressed.
  /// * [actionDisabled] - Fill color of disabled controls.
  /// * [focus] - Color of the focus ring around the focused control.
  /// * [infoBackground] - Background color of information messages.
  /// * [infoForeground] - Color of text and icons on [infoBackground].
  /// * [successBackground] - Background color of success messages.
  /// * [successForeground] - Color of text and icons on [successBackground].
  /// * [warningBackground] - Background color of warning messages.
  /// * [warningForeground] - Color of text and icons on [warningBackground].
  /// * [errorBackground] - Background color of error messages.
  /// * [errorForeground] - Color of text and icons on [errorBackground], and of error text, such as a field's error, on [background] and [surface].
  const DsColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.textOnAction,
    required this.actionPrimary,
    required this.actionPrimaryPressed,
    required this.actionDisabled,
    required this.focus,
    required this.infoBackground,
    required this.infoForeground,
    required this.successBackground,
    required this.successForeground,
    required this.warningBackground,
    required this.warningForeground,
    required this.errorBackground,
    required this.errorForeground,
  });

  /// Background color of a page.
  final Color background;

  /// Color of raised content on the page, such as cards, fields, and sheets.
  final Color surface;

  /// Color of secondary surfaces, such as a selected row or a grouped area.
  final Color surfaceVariant;

  /// Color of borders and dividers.
  final Color border;

  /// Color of primary text on [background], [surface], and [surfaceVariant].
  final Color textPrimary;

  /// Color of supporting text, such as subtitles, hints, and helper text, on [background], [surface], and [surfaceVariant].
  final Color textSecondary;

  /// Color of text and icons in disabled controls.
  final Color textDisabled;

  /// Color of text and icons on [actionPrimary] and [actionPrimaryPressed].
  final Color textOnAction;

  /// Color of the primary action: the primary button fill, and the text of secondary and tertiary buttons.
  final Color actionPrimary;

  /// Color of the primary action while it is pressed.
  final Color actionPrimaryPressed;

  /// Fill color of disabled controls.
  final Color actionDisabled;

  /// Color of the focus ring around the focused control.
  final Color focus;

  /// Background color of information messages.
  final Color infoBackground;

  /// Color of text and icons on [infoBackground].
  final Color infoForeground;

  /// Background color of success messages.
  final Color successBackground;

  /// Color of text and icons on [successBackground].
  final Color successForeground;

  /// Background color of warning messages.
  final Color warningBackground;

  /// Color of text and icons on [warningBackground].
  final Color warningForeground;

  /// Background color of error messages.
  final Color errorBackground;

  /// Color of text and icons on [errorBackground], and of error text, such as a field's error, on [background] and [surface].
  final Color errorForeground;

  /// Returns a copy of these roles with the given roles replaced.
  ///
  /// Parameters: each parameter replaces the role of the same name; a null
  /// parameter keeps the current role.
  @override
  DsColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? textOnAction,
    Color? actionPrimary,
    Color? actionPrimaryPressed,
    Color? actionDisabled,
    Color? focus,
    Color? infoBackground,
    Color? infoForeground,
    Color? successBackground,
    Color? successForeground,
    Color? warningBackground,
    Color? warningForeground,
    Color? errorBackground,
    Color? errorForeground,
  }) {
    return DsColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      textOnAction: textOnAction ?? this.textOnAction,
      actionPrimary: actionPrimary ?? this.actionPrimary,
      actionPrimaryPressed: actionPrimaryPressed ?? this.actionPrimaryPressed,
      actionDisabled: actionDisabled ?? this.actionDisabled,
      focus: focus ?? this.focus,
      infoBackground: infoBackground ?? this.infoBackground,
      infoForeground: infoForeground ?? this.infoForeground,
      successBackground: successBackground ?? this.successBackground,
      successForeground: successForeground ?? this.successForeground,
      warningBackground: warningBackground ?? this.warningBackground,
      warningForeground: warningForeground ?? this.warningForeground,
      errorBackground: errorBackground ?? this.errorBackground,
      errorForeground: errorForeground ?? this.errorForeground,
    );
  }

  /// Returns the roles between these and [other], for animated theme
  /// changes.
  ///
  /// Parameters:
  /// * [other] - The roles to move toward. When it is not a [DsColors], these
  ///   roles are returned unchanged.
  /// * [t] - The position between the two, from 0 (these) to 1 ([other]).
  @override
  DsColors lerp(covariant ThemeExtension<DsColors>? other, double t) {
    if (other is! DsColors) return this;
    return DsColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      textOnAction: Color.lerp(textOnAction, other.textOnAction, t)!,
      actionPrimary: Color.lerp(actionPrimary, other.actionPrimary, t)!,
      actionPrimaryPressed: Color.lerp(
        actionPrimaryPressed,
        other.actionPrimaryPressed,
        t,
      )!,
      actionDisabled: Color.lerp(actionDisabled, other.actionDisabled, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      infoBackground: Color.lerp(infoBackground, other.infoBackground, t)!,
      infoForeground: Color.lerp(infoForeground, other.infoForeground, t)!,
      successBackground: Color.lerp(
        successBackground,
        other.successBackground,
        t,
      )!,
      successForeground: Color.lerp(
        successForeground,
        other.successForeground,
        t,
      )!,
      warningBackground: Color.lerp(
        warningBackground,
        other.warningBackground,
        t,
      )!,
      warningForeground: Color.lerp(
        warningForeground,
        other.warningForeground,
        t,
      )!,
      errorBackground: Color.lerp(errorBackground, other.errorBackground, t)!,
      errorForeground: Color.lerp(errorForeground, other.errorForeground, t)!,
    );
  }
}

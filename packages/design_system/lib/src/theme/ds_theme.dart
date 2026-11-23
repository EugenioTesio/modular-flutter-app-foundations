/// @docImport 'ds_theme_context.dart';
library;

import 'package:flutter/material.dart';

import '../tokens/ds_colors.dart';
import '../tokens/ds_palette.dart';
import '../tokens/ds_radius.dart';
import '../tokens/ds_typography.dart';
import 'ds_brand.dart';
import 'ds_contrast.dart';

/// Factory for the application's light and dark [ThemeData], derived from
/// one [DsBrand].
///
/// Use this once, in the host's `MaterialApp`: `theme: DsTheme.light()` and
/// `darkTheme: DsTheme.dark()`, with the same brand for both.
///
/// This is **not** something micro apps call: they read the resulting
/// tokens through `context.dsColors` and `context.dsTypography`.
///
/// Built-in: each theme installs [DsColors] and [DsTypography] as
/// [ThemeExtension]s, and aligns the Material color scheme, text theme, and
/// component themes (app bar, input fields, list tiles, cards, dividers, and
/// progress indicators) with the same roles. Material widgets used next to
/// design system components therefore match them.
///
/// Usage from a host:
/// ```dart
/// MaterialApp.router(
///   theme: DsTheme.light(brand: brand),
///   darkTheme: DsTheme.dark(brand: brand),
///   routerConfig: router,
/// );
/// ```
abstract final class DsTheme {
  /// Returns the light theme for [brand].
  ///
  /// Parameters:
  /// * [brand] - The brand the action, focus, and information roles and the
  ///   font family derive from. Defaults to [DsBrand.standard].
  static ThemeData light({DsBrand brand = DsBrand.standard}) => _theme(
    Brightness.light,
    brand,
    _resolveColors(
      brand,
      background: DsPalette.neutral50,
      surface: DsPalette.neutral0,
      surfaceVariant: DsPalette.neutral100,
      border: DsPalette.neutral300,
      textPrimary: DsPalette.neutral900,
      textSecondary: DsPalette.neutral600,
      textDisabled: DsPalette.neutral400,
      actionDisabled: DsPalette.neutral200,
      contrastEnd: DsPalette.neutral900,
      infoTint: 0.10,
      successBackground: DsPalette.success100,
      successForeground: DsPalette.success700,
      warningBackground: DsPalette.warning100,
      warningForeground: DsPalette.warning700,
      errorBackground: DsPalette.error100,
      errorForeground: DsPalette.error700,
    ),
  );

  /// Returns the dark theme for [brand].
  ///
  /// Parameters:
  /// * [brand] - The brand the action, focus, and information roles and the
  ///   font family derive from. Defaults to [DsBrand.standard].
  static ThemeData dark({DsBrand brand = DsBrand.standard}) => _theme(
    Brightness.dark,
    brand,
    _resolveColors(
      brand,
      background: DsPalette.neutral900,
      surface: DsPalette.neutral800,
      surfaceVariant: DsPalette.neutral700,
      border: DsPalette.neutral600,
      textPrimary: DsPalette.neutral50,
      textSecondary: DsPalette.neutral300,
      textDisabled: DsPalette.neutral500,
      actionDisabled: DsPalette.neutral700,
      contrastEnd: DsPalette.neutral0,
      infoTint: 0.24,
      successBackground: DsPalette.success700,
      successForeground: DsPalette.success100,
      warningBackground: DsPalette.warning700,
      warningForeground: DsPalette.warning100,
      errorBackground: DsPalette.error700,
      errorForeground: DsPalette.error100,
    ),
  );

  static const double _textMinimum = 4.5;

  static DsColors _resolveColors(
    DsBrand brand, {
    required Color background,
    required Color surface,
    required Color surfaceVariant,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Color textDisabled,
    required Color actionDisabled,
    required Color contrastEnd,
    required double infoTint,
    required Color successBackground,
    required Color successForeground,
    required Color warningBackground,
    required Color warningForeground,
    required Color errorBackground,
    required Color errorForeground,
  }) {
    // The action color doubles as text color for secondary and tertiary
    // buttons, so it must reach the text minimum on the page.
    var action = DsContrast.ensure(
      brand.primary,
      against: [background, surface],
      minimum: _textMinimum,
      towards: contrastEnd,
    );
    final textOnAction = DsContrast.bestText(
      action,
      light: DsPalette.neutral0,
      dark: DsPalette.neutral900,
    );
    final awayFromText = textOnAction == DsPalette.neutral0
        ? DsPalette.neutral900
        : DsPalette.neutral0;
    action = DsContrast.ensure(
      action,
      against: [textOnAction],
      minimum: _textMinimum,
      towards: awayFromText,
    );
    final infoBackground = Color.alphaBlend(
      action.withValues(alpha: infoTint),
      surface,
    );
    return DsColors(
      background: background,
      surface: surface,
      surfaceVariant: surfaceVariant,
      border: border,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textDisabled: textDisabled,
      textOnAction: textOnAction,
      actionPrimary: action,
      actionPrimaryPressed: Color.lerp(action, awayFromText, 0.2)!,
      actionDisabled: actionDisabled,
      focus: action,
      infoBackground: infoBackground,
      infoForeground: DsContrast.ensure(
        action,
        against: [infoBackground],
        minimum: _textMinimum,
        towards: contrastEnd,
      ),
      successBackground: successBackground,
      successForeground: successForeground,
      warningBackground: warningBackground,
      warningForeground: warningForeground,
      errorBackground: errorBackground,
      errorForeground: errorForeground,
    );
  }

  static DsTypography _typography(String? fontFamily) => DsTypography(
    display: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32,
      height: 1.25,
      fontWeight: FontWeight.w700,
    ),
    headline: TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      height: 1.3,
      fontWeight: FontWeight.w700,
    ),
    title: TextStyle(
      fontFamily: fontFamily,
      fontSize: 20,
      height: 1.3,
      fontWeight: FontWeight.w600,
    ),
    body: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w400,
    ),
    bodyStrong: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w600,
    ),
    label: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      height: 1.4,
      fontWeight: FontWeight.w600,
    ),
    caption: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      height: 1.4,
      fontWeight: FontWeight.w400,
    ),
  );

  static ThemeData _theme(
    Brightness brightness,
    DsBrand brand,
    DsColors colors,
  ) {
    final typography = _typography(brand.fontFamily);
    final radius = BorderRadius.circular(DsRadius.md);
    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: brand.fontFamily,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.actionPrimary,
        onPrimary: colors.textOnAction,
        secondary: colors.actionPrimary,
        onSecondary: colors.textOnAction,
        error: colors.errorForeground,
        onError: colors.errorBackground,
        errorContainer: colors.errorBackground,
        onErrorContainer: colors.errorForeground,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        onSurfaceVariant: colors.textSecondary,
        surfaceContainerHighest: colors.surfaceVariant,
        outline: colors.border,
        outlineVariant: colors.border,
      ),
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      dividerColor: colors.border,
      focusColor: colors.focus.withValues(alpha: 0.12),
      textTheme: TextTheme(
        displayLarge: typography.display,
        headlineMedium: typography.headline,
        titleLarge: typography.title,
        titleMedium: typography.bodyStrong,
        bodyLarge: typography.body,
        bodyMedium: typography.body,
        labelLarge: typography.label,
        bodySmall: typography.caption,
      ).apply(bodyColor: colors.textPrimary, displayColor: colors.textPrimary),
      iconTheme: IconThemeData(color: colors.textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: typography.title.copyWith(color: colors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        labelStyle: typography.body.copyWith(color: colors.textSecondary),
        floatingLabelStyle: typography.label.copyWith(
          color: colors.textPrimary,
        ),
        hintStyle: typography.body.copyWith(color: colors.textSecondary),
        helperStyle: typography.caption.copyWith(color: colors.textSecondary),
        errorStyle: typography.caption.copyWith(color: colors.errorForeground),
        border: outline(colors.border),
        enabledBorder: outline(colors.textSecondary),
        focusedBorder: outline(colors.focus, 2),
        errorBorder: outline(colors.errorForeground),
        focusedErrorBorder: outline(colors.errorForeground, 2),
        disabledBorder: outline(colors.actionDisabled),
      ),
      listTileTheme: ListTileThemeData(
        textColor: colors.textPrimary,
        iconColor: colors.textSecondary,
        titleTextStyle: typography.body.copyWith(color: colors.textPrimary),
        subtitleTextStyle: typography.caption.copyWith(
          color: colors.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: colors.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.border, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.actionPrimary,
      ),
      extensions: [colors, typography],
    );
  }
}

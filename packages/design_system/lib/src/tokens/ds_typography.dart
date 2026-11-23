/// @docImport '../theme/ds_brand.dart';
/// @docImport '../theme/ds_theme.dart';
/// @docImport 'ds_colors.dart';
library;

import 'package:flutter/material.dart';

/// Semantic text styles, resolved for the active theme and brand.
///
/// Use this for every text style in a screen, through `context.dsTypography`,
/// and add the color from [DsColors]: `typography.body.copyWith(color:
/// colors.textSecondary)`.
///
/// This is **not** a color source: the styles carry size, weight, line
/// height, and font family only, so the same style works on any background.
///
/// Built-in: [DsTheme.light] and [DsTheme.dark] create it with the font
/// family of [DsBrand.fontFamily] and install it as a [ThemeExtension]. When
/// the brand names no font, the styles use the platform font.
///
/// Sizes: [display] 32, [headline] 24, [title] 20, [body] and [bodyStrong]
/// 16, [label] 14, and [caption] 12. They scale with the user's text size
/// setting.
///
/// Usage from a micro app:
/// ```dart
/// final typography = context.dsTypography;
/// return Text(
///   'Accounts',
///   style: typography.headline.copyWith(color: context.dsColors.textPrimary),
/// );
/// ```
@immutable
final class DsTypography extends ThemeExtension<DsTypography> {
  /// Creates a set of text styles. Themes call this; screens read the styles
  /// through `context.dsTypography` instead.
  ///
  /// Parameters:
  /// * [display] - Style of the largest text, such as an amount on a summary.
  /// * [headline] - Style of section and page headings.
  /// * [title] - Style of app bar titles and card titles.
  /// * [body] - Style of running text.
  /// * [bodyStrong] - Style of emphasized running text.
  /// * [label] - Style of button and field labels.
  /// * [caption] - Style of small supporting text.
  const DsTypography({
    required this.display,
    required this.headline,
    required this.title,
    required this.body,
    required this.bodyStrong,
    required this.label,
    required this.caption,
  });

  /// Style of the largest text, such as an amount on a summary.
  final TextStyle display;

  /// Style of section and page headings.
  final TextStyle headline;

  /// Style of app bar titles and card titles.
  final TextStyle title;

  /// Style of running text.
  final TextStyle body;

  /// Style of emphasized running text.
  final TextStyle bodyStrong;

  /// Style of button and field labels.
  final TextStyle label;

  /// Style of small supporting text.
  final TextStyle caption;

  /// Returns a copy of these styles with the given styles replaced.
  ///
  /// Parameters: each parameter replaces the style of the same name; a null
  /// parameter keeps the current style.
  @override
  DsTypography copyWith({
    TextStyle? display,
    TextStyle? headline,
    TextStyle? title,
    TextStyle? body,
    TextStyle? bodyStrong,
    TextStyle? label,
    TextStyle? caption,
  }) {
    return DsTypography(
      display: display ?? this.display,
      headline: headline ?? this.headline,
      title: title ?? this.title,
      body: body ?? this.body,
      bodyStrong: bodyStrong ?? this.bodyStrong,
      label: label ?? this.label,
      caption: caption ?? this.caption,
    );
  }

  /// Returns the styles between these and [other], for animated theme
  /// changes.
  ///
  /// Parameters:
  /// * [other] - The styles to move toward. When it is not a [DsTypography],
  ///   these styles are returned unchanged.
  /// * [t] - The position between the two, from 0 (these) to 1 ([other]).
  @override
  DsTypography lerp(covariant ThemeExtension<DsTypography>? other, double t) {
    if (other is! DsTypography) return this;
    return DsTypography(
      display: TextStyle.lerp(display, other.display, t)!,
      headline: TextStyle.lerp(headline, other.headline, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodyStrong: TextStyle.lerp(bodyStrong, other.bodyStrong, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
    );
  }
}

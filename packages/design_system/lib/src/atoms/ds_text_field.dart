/// @docImport '../tokens/ds_colors.dart';
library;

import 'package:flutter/material.dart';

import '../theme/ds_theme_context.dart';
import '../tokens/ds_radius.dart';

/// Widget that lets the user enter text: the design system's text field.
///
/// Use this for every text input, such as a sign-in form or a transfer
/// amount. Validate in the micro app and pass the message in [errorText].
///
/// This is **not** a form: it holds no validation rules. Keep the rules and
/// the [TextEditingController] in the screen's state.
///
/// Built-in:
/// * [label] is shown above the input and is its accessible label.
/// * When [errorText] is not null, the field shows it in
///   [DsColors.errorForeground] with an error border, and screen readers
///   announce it.
/// * When [enabled] is false, the field ignores taps and uses
///   [DsColors.actionDisabled] and [DsColors.textDisabled].
/// * A focused field shows a border in [DsColors.focus].
///
/// Usage from a micro app:
/// ```dart
/// DsTextField(
///   label: 'Amount',
///   controller: amountController,
///   keyboardType: const TextInputType.numberWithOptions(decimal: true),
///   errorText: amountError,
///   onChanged: (_) => setState(() => amountError = null),
/// )
/// ```
final class DsTextField extends StatelessWidget {
  /// Creates a text field.
  ///
  /// Parameters:
  /// * [label] - The visible label, which is also the accessible label.
  ///   Localize it.
  /// * [controller] - Optional controller that holds the text. When null,
  ///   the field keeps its own text.
  /// * [hint] - Optional example shown while the field is empty.
  /// * [helperText] - Optional guidance shown below the field.
  /// * [errorText] - Optional error message. When not null, it replaces
  ///   [helperText] and shows the error state.
  /// * [obscureText] - Whether to hide the text, as for a password. Defaults
  ///   to false.
  /// * [enabled] - Whether the field accepts input. Defaults to true.
  /// * [keyboardType] - Optional keyboard type, such as
  ///   [TextInputType.emailAddress].
  /// * [textInputAction] - Optional action button of the keyboard, such as
  ///   [TextInputAction.next].
  /// * [onChanged] - Optional callback with the text after each edit.
  /// * [onSubmitted] - Optional callback with the text when the user submits
  ///   from the keyboard.
  const DsTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helperText,
    this.errorText,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
  });

  /// The visible label, which is also the accessible label.
  final String label;

  /// Optional controller that holds the text.
  final TextEditingController? controller;

  /// Optional example shown while the field is empty.
  final String? hint;

  /// Optional guidance shown below the field.
  final String? helperText;

  /// Optional error message; when set, the field shows the error state.
  final String? errorText;

  /// Whether the text is hidden, as for a password.
  final bool obscureText;

  /// Whether the field accepts input.
  final bool enabled;

  /// Optional keyboard type.
  final TextInputType? keyboardType;

  /// Optional action button of the keyboard.
  final TextInputAction? textInputAction;

  /// Optional callback with the text after each edit.
  final ValueChanged<String>? onChanged;

  /// Optional callback with the text when the user submits from the
  /// keyboard.
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final textColor = enabled ? colors.textPrimary : colors.textDisabled;
    final supportColor = enabled ? colors.textSecondary : colors.textDisabled;
    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.md),
          borderSide: BorderSide(color: color, width: width),
        );

    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      cursorColor: colors.focus,
      style: typography.body.copyWith(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        errorText: errorText,
        helperMaxLines: 3,
        errorMaxLines: 3,
        filled: true,
        fillColor: enabled ? colors.surface : colors.actionDisabled,
        labelStyle: typography.body.copyWith(color: supportColor),
        floatingLabelStyle: typography.label.copyWith(
          color: errorText != null ? colors.errorForeground : textColor,
        ),
        hintStyle: typography.body.copyWith(color: supportColor),
        helperStyle: typography.caption.copyWith(color: supportColor),
        errorStyle: typography.caption.copyWith(color: colors.errorForeground),
        enabledBorder: outline(colors.textSecondary),
        focusedBorder: outline(colors.focus, 2),
        errorBorder: outline(colors.errorForeground),
        focusedErrorBorder: outline(colors.errorForeground, 2),
        disabledBorder: outline(colors.actionDisabled),
      ),
    );
  }
}

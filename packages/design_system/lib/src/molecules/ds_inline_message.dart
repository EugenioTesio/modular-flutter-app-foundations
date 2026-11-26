/// @docImport '../tokens/ds_colors.dart';
library;

import 'package:flutter/material.dart';

import '../theme/ds_theme_context.dart';
import '../tokens/ds_radius.dart';
import '../tokens/ds_spacing.dart';

/// Value that sets the meaning, and so the colors and icon, of a
/// [DsInlineMessage].
enum DsMessageTone {
  /// Neutral information, in the brand-derived information roles.
  info,

  /// A completed action, in the success roles.
  success,

  /// Something that needs attention but does not block, in the warning
  /// roles.
  warning,

  /// A failure that blocks the user, in the error roles.
  error,
}

/// Widget that shows a short message inside the page, with an optional
/// action.
///
/// Use this for feedback that belongs to a section of the screen: a failed
/// load with a "Retry" action, a warning above a form, or a confirmation
/// after saving.
///
/// This is **not** a field error: pass a field's validation message to the
/// field's `errorText` instead, so it sits next to the input.
///
/// Built-in:
/// * Each [DsMessageTone] uses its own pair of [DsColors] roles, for example
///   [DsColors.errorBackground] with [DsColors.errorForeground], and its own
///   icon, so the tone is not shown by color alone.
/// * The message is one region for screen readers. Error and warning
///   messages are announced when they appear.
/// * The action button is at least 48 × 48.
///
/// Usage from a micro app:
/// ```dart
/// DsInlineMessage(
///   tone: DsMessageTone.error,
///   title: 'Balance unavailable',
///   message: 'Check your connection and try again.',
///   actionLabel: 'Retry',
///   onAction: reload,
/// )
/// ```
final class DsInlineMessage extends StatelessWidget {
  /// Creates an inline message.
  ///
  /// Parameters:
  /// * [message] - The text of the message. Localize it.
  /// * [tone] - The meaning of the message. Defaults to
  ///   [DsMessageTone.info].
  /// * [title] - Optional short heading above [message].
  /// * [actionLabel] - Optional label of the action button. Set it together
  ///   with [onAction].
  /// * [onAction] - Optional callback of the action button. Set it together
  ///   with [actionLabel].
  const DsInlineMessage({
    super.key,
    required this.message,
    this.tone = DsMessageTone.info,
    this.title,
    this.actionLabel,
    this.onAction,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'Set actionLabel and onAction together.',
       );

  /// The text of the message.
  final String message;

  /// The meaning of the message.
  final DsMessageTone tone;

  /// Optional short heading above [message].
  final String? title;

  /// Optional label of the action button.
  final String? actionLabel;

  /// Optional callback of the action button.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final (background, foreground, icon) = switch (tone) {
      DsMessageTone.info => (
        colors.infoBackground,
        colors.infoForeground,
        Icons.info_outline,
      ),
      DsMessageTone.success => (
        colors.successBackground,
        colors.successForeground,
        Icons.check_circle_outline,
      ),
      DsMessageTone.warning => (
        colors.warningBackground,
        colors.warningForeground,
        Icons.warning_amber_outlined,
      ),
      DsMessageTone.error => (
        colors.errorBackground,
        colors.errorForeground,
        Icons.error_outline,
      ),
    };
    final title = this.title;
    final actionLabel = this.actionLabel;

    return Semantics(
      container: true,
      liveRegion: tone == DsMessageTone.error || tone == DsMessageTone.warning,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(DsRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DsSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(child: Icon(icon, color: foreground, size: 20)),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null)
                      Text(
                        title,
                        style: typography.bodyStrong.copyWith(
                          color: foreground,
                        ),
                      ),
                    Text(
                      message,
                      style: typography.body.copyWith(color: foreground),
                    ),
                    if (actionLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: DsSpacing.xs),
                        child: TextButton(
                          onPressed: onAction,
                          style: TextButton.styleFrom(
                            foregroundColor: foreground,
                            minimumSize: const Size(48, 48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: DsSpacing.xs,
                            ),
                            textStyle: typography.label,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DsRadius.md),
                            ),
                          ),
                          child: Text(actionLabel),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// @docImport '../tokens/ds_colors.dart';
/// @docImport 'ds_inline_message.dart';
library;

import 'package:flutter/material.dart';

import '../atoms/ds_button.dart';
import '../theme/ds_theme_context.dart';
import '../tokens/ds_spacing.dart';

/// Widget that fills an area that has no content yet, and suggests what to
/// do next.
///
/// Use this when a list or section is empty, such as "No transfers yet", or
/// when a feature is unavailable and the screen has nothing else to show.
///
/// This is **not** an error inside other content: for a failed load next to
/// other content, use [DsInlineMessage].
///
/// Built-in:
/// * The content is centered: an optional icon in
///   [DsColors.textSecondary], the [title] as a heading in
///   [DsColors.textPrimary], the [message] in [DsColors.textSecondary], and
///   an optional primary [DsButton].
/// * The icon is decorative and hidden from screen readers.
///
/// Usage from a micro app:
/// ```dart
/// DsEmptyState(
///   icon: Icons.receipt_long,
///   title: 'No transfers yet',
///   message: 'Transfers you make appear here.',
///   actionLabel: 'New transfer',
///   onAction: () => navigator.push('/transfers/new'),
/// )
/// ```
final class DsEmptyState extends StatelessWidget {
  /// Creates an empty state.
  ///
  /// Parameters:
  /// * [title] - What is missing, as a short heading. Localize it.
  /// * [message] - Optional explanation or next step below the title.
  /// * [icon] - Optional decorative icon above the title.
  /// * [actionLabel] - Optional label of the action button. Set it together
  ///   with [onAction].
  /// * [onAction] - Optional callback of the action button. Set it together
  ///   with [actionLabel].
  const DsEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'Set actionLabel and onAction together.',
       );

  /// What is missing, as a short heading.
  final String title;

  /// Optional explanation or next step below the title.
  final String? message;

  /// Optional decorative icon above the title.
  final IconData? icon;

  /// Optional label of the action button.
  final String? actionLabel;

  /// Optional callback of the action button.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final message = this.message;
    final actionLabel = this.actionLabel;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DsSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              ExcludeSemantics(
                child: Icon(icon, size: 48, color: colors.textSecondary),
              ),
              const SizedBox(height: DsSpacing.md),
            ],
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: typography.title.copyWith(color: colors.textPrimary),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: DsSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: typography.body.copyWith(color: colors.textSecondary),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: DsSpacing.lg),
              DsButton(label: actionLabel, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

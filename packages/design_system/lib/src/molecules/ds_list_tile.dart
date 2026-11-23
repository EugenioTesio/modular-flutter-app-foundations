/// @docImport '../tokens/ds_colors.dart';
/// @docImport 'ds_card.dart';
library;

import 'package:flutter/material.dart';

import '../theme/ds_theme_context.dart';
import '../tokens/ds_spacing.dart';

/// Widget that shows one row of a list: a title, an optional subtitle, and
/// optional leading and trailing widgets.
///
/// Use this for lists of items, such as accounts, transactions, or settings.
/// Set [onTap] when the row opens something.
///
/// This is **not** a container for free-form content: use [DsCard] for that.
///
/// Built-in:
/// * The title uses [DsColors.textPrimary] and the subtitle
///   [DsColors.textSecondary]; long text wraps instead of overflowing.
/// * When [onTap] is set, the row is one button for screen readers, labeled
///   by its title and subtitle, and at least 48 high.
///
/// Usage from a micro app:
/// ```dart
/// DsListTile(
///   title: account.name,
///   subtitle: account.maskedNumber,
///   leading: const Icon(Icons.account_balance),
///   trailing: const Icon(Icons.chevron_right),
///   onTap: () => navigator.push('/accounts/details/${account.id}'),
/// )
/// ```
final class DsListTile extends StatelessWidget {
  /// Creates a list row.
  ///
  /// Parameters:
  /// * [title] - The main text. Localize it.
  /// * [subtitle] - Optional supporting text below the title.
  /// * [leading] - Optional widget before the text, usually an [Icon].
  /// * [trailing] - Optional widget after the text, such as a chevron or an
  ///   amount.
  /// * [onTap] - Optional callback that makes the row tappable.
  const DsListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  /// The main text.
  final String title;

  /// Optional supporting text below the title.
  final String? subtitle;

  /// Optional widget before the text.
  final Widget? leading;

  /// Optional widget after the text.
  final Widget? trailing;

  /// Optional callback that makes the row tappable.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final subtitle = this.subtitle;
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        title: Text(
          title,
          style: typography.body.copyWith(color: colors.textPrimary),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle,
                style: typography.caption.copyWith(color: colors.textSecondary),
              ),
        leading: leading,
        trailing: trailing,
        onTap: onTap,
        minTileHeight: 48,
        contentPadding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
        iconColor: colors.textSecondary,
        textColor: colors.textPrimary,
        focusColor: colors.focus.withValues(alpha: 0.12),
        hoverColor: colors.textPrimary.withValues(alpha: 0.04),
        splashColor: colors.textPrimary.withValues(alpha: 0.08),
      ),
    );
  }
}

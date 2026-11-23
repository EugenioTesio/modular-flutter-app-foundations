/// @docImport '../tokens/ds_colors.dart';
/// @docImport 'ds_list_tile.dart';
library;

import 'package:flutter/material.dart';

import '../theme/ds_theme_context.dart';
import '../tokens/ds_radius.dart';
import '../tokens/ds_spacing.dart';

/// Widget that groups related content on a raised surface.
///
/// Use this to set a block of content apart from the page, such as an
/// account summary or a promotion. Set [onTap] to make the whole card one
/// tappable element.
///
/// This is **not** a list row: for a row with a title, a subtitle, and an
/// optional icon, use [DsListTile].
///
/// Built-in:
/// * The card uses [DsColors.surface], a [DsColors.border] outline, and
///   rounded corners.
/// * When [onTap] is set, the card is one button for screen readers, at
///   least 48 high. Its label is [semanticsLabel] when set, and otherwise the
///   text inside the card.
///
/// Usage from a micro app:
/// ```dart
/// DsCard(
///   onTap: () => navigator.push('/accounts/details/${account.id}'),
///   semanticsLabel: 'Checking account, balance ${account.balance}',
///   child: AccountSummary(account: account),
/// )
/// ```
final class DsCard extends StatelessWidget {
  /// Creates a card.
  ///
  /// Parameters:
  /// * [child] - The content of the card.
  /// * [onTap] - Optional callback that makes the whole card tappable.
  /// * [semanticsLabel] - Optional label that replaces the content for
  ///   screen readers. Set it whenever [onTap] is set and the content is not
  ///   a short, clear text. Localize it.
  /// * [padding] - Space around [child]. Defaults to [DsSpacing.md] on every
  ///   side.
  const DsCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticsLabel,
    this.padding = const EdgeInsets.all(DsSpacing.md),
  });

  /// The content of the card.
  final Widget child;

  /// Optional callback that makes the whole card tappable.
  final VoidCallback? onTap;

  /// Optional label that replaces the content for screen readers.
  final String? semanticsLabel;

  /// Space around [child].
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DsRadius.md),
      side: BorderSide(color: colors.border),
    );
    final content = Padding(padding: padding, child: child);
    final tap = onTap;
    if (tap == null) {
      return Material(
        color: colors.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: content,
      );
    }

    final card = Semantics(
      container: true,
      button: true,
      label: semanticsLabel,
      onTap: tap,
      excludeSemantics: semanticsLabel != null,
      child: Material(
        color: colors.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: tap,
          customBorder: shape,
          focusColor: colors.focus.withValues(alpha: 0.12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: content,
          ),
        ),
      ),
    );
    return semanticsLabel == null ? MergeSemantics(child: card) : card;
  }
}

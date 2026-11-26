/// @docImport '../tokens/ds_colors.dart';
library;

import 'package:flutter/material.dart';

import '../atoms/ds_button.dart';
import '../theme/ds_theme_context.dart';
import '../tokens/ds_spacing.dart';

/// Widget that lays out a whole screen: a title bar, a padded body, and an
/// optional primary action pinned at the bottom.
///
/// Use this as the root widget of every micro app screen, so screens share
/// one structure, padding, and back behavior.
///
/// This is **not** a navigation shell: tabs or a side menu shared by several
/// screens belong in a route group's layout.
///
/// Built-in:
/// * The page uses [DsColors.background], and the title bar shows [title]
///   in [DsColors.textPrimary].
/// * The [body] sits inside the safe area, padded by [DsSpacing.md] on every
///   side. Make it scrollable when it can be taller than the screen.
/// * The [primaryAction] is pinned at the bottom, inside the safe area, and
///   stretched to the full width, whatever its own `expand` setting.
/// * Back: when [onBack] is set, the title bar shows a back button that calls
///   it. Otherwise the platform behavior applies: a back button appears when
///   the route can be popped.
///
/// Usage from a micro app:
/// ```dart
/// DsPageScaffold(
///   title: 'New transfer',
///   body: TransferForm(controller: controller),
///   primaryAction: DsButton(
///     label: 'Continue',
///     onPressed: controller.isValid ? submit : null,
///   ),
/// )
/// ```
final class DsPageScaffold extends StatelessWidget {
  /// Creates a page.
  ///
  /// Parameters:
  /// * [title] - The title shown in the title bar. Localize it.
  /// * [body] - The content of the page.
  /// * [primaryAction] - Optional main action, pinned at the bottom and
  ///   stretched to the full width.
  /// * [onBack] - Optional callback of the back button. When null, the
  ///   platform back behavior applies.
  const DsPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.primaryAction,
    this.onBack,
  });

  /// The title shown in the title bar.
  final String title;

  /// The content of the page.
  final Widget body;

  /// Optional main action, pinned at the bottom.
  final DsButton? primaryAction;

  /// Optional callback of the back button.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final onBack = this.onBack;
    final primaryAction = this.primaryAction;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(title),
        leading: onBack == null ? null : BackButton(onPressed: onBack),
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: context.dsTypography.title.copyWith(
          color: colors.textPrimary,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DsSpacing.md),
          child: body,
        ),
      ),
      bottomNavigationBar: primaryAction == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DsSpacing.md,
                  0,
                  DsSpacing.md,
                  DsSpacing.md,
                ),
                child: SizedBox(width: double.infinity, child: primaryAction),
              ),
            ),
    );
  }
}

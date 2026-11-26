/// Library of the interim design system of the modular Flutter app: tokens,
/// light and dark themes derived from one brand, and accessible components.
///
/// Use this through `package:foundations/foundations.dart`, which re-exports
/// it unchanged. Micro apps never import it directly. It provides:
///
/// * **Primitive tokens**: [DsPalette], [DsSpacing], and [DsRadius].
/// * **Semantic tokens**: [DsColors] and [DsTypography], read with
///   `context.dsColors` and `context.dsTypography` ([DsThemeContext]).
/// * **Brand and themes**: [DsBrand], [DsTheme.light], and [DsTheme.dark].
/// * **Atoms**: [DsButton], [DsTextField], and [DsLoadingIndicator].
/// * **Molecules**: [DsCard], [DsListTile], [DsInlineMessage], and
///   [DsEmptyState].
/// * **Template**: [DsPageScaffold].
///
/// This is **not** a widget library to extend by subclassing: every class is
/// `final`, so screens compose components instead.
///
/// Built-in: every component reads only semantic tokens, so the host's brand
/// and the user's light or dark setting restyle all of them. Every component
/// meets the tap-target, labeling, and text-contrast guidelines, and lays out
/// at twice the default text size on a 320-wide screen.
///
/// This package lives in the Foundations repository for now. It will move to
/// its own repository without changing its package name or this library.
///
/// Usage from a micro app:
/// ```dart
/// import 'package:foundations/foundations.dart';
///
/// final class SignInScreen extends StatelessWidget {
///   const SignInScreen({super.key, required this.onSubmit});
///
///   final VoidCallback onSubmit;
///
///   @override
///   Widget build(BuildContext context) {
///     return DsPageScaffold(
///       title: 'Sign in',
///       body: const Column(
///         children: [
///           DsTextField(label: 'Email'),
///           SizedBox(height: DsSpacing.md),
///           DsTextField(label: 'Password', obscureText: true),
///         ],
///       ),
///       primaryAction: DsButton(label: 'Sign in', onPressed: onSubmit),
///     );
///   }
/// }
/// ```
///
/// @docImport 'src/atoms/ds_button.dart';
/// @docImport 'src/atoms/ds_loading_indicator.dart';
/// @docImport 'src/atoms/ds_text_field.dart';
/// @docImport 'src/molecules/ds_card.dart';
/// @docImport 'src/molecules/ds_empty_state.dart';
/// @docImport 'src/molecules/ds_inline_message.dart';
/// @docImport 'src/molecules/ds_list_tile.dart';
/// @docImport 'src/templates/ds_page_scaffold.dart';
/// @docImport 'src/theme/ds_brand.dart';
/// @docImport 'src/theme/ds_theme.dart';
/// @docImport 'src/theme/ds_theme_context.dart';
/// @docImport 'src/tokens/ds_colors.dart';
/// @docImport 'src/tokens/ds_palette.dart';
/// @docImport 'src/tokens/ds_radius.dart';
/// @docImport 'src/tokens/ds_spacing.dart';
/// @docImport 'src/tokens/ds_typography.dart';
library;

export 'src/atoms/ds_button.dart';
export 'src/atoms/ds_loading_indicator.dart';
export 'src/atoms/ds_text_field.dart';
export 'src/molecules/ds_card.dart';
export 'src/molecules/ds_empty_state.dart';
export 'src/molecules/ds_inline_message.dart';
export 'src/molecules/ds_list_tile.dart';
export 'src/templates/ds_page_scaffold.dart';
export 'src/theme/ds_brand.dart';
export 'src/theme/ds_theme.dart';
export 'src/theme/ds_theme_context.dart';
export 'src/tokens/ds_colors.dart';
export 'src/tokens/ds_palette.dart';
export 'src/tokens/ds_radius.dart';
export 'src/tokens/ds_spacing.dart';
export 'src/tokens/ds_typography.dart';

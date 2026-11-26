/// Primitive spacing tokens: the fixed steps for padding, gaps, and margins,
/// in logical pixels.
///
/// Use this for every padding and gap in a screen, so layouts share one
/// rhythm: `EdgeInsets.all(DsSpacing.md)` rather than `EdgeInsets.all(16)`.
///
/// This is **not** a size for components: tap targets and icons have their
/// own minimums.
///
/// The scale is 4 · 8 · 12 · 16 · 24 · 32 · 48.
///
/// Usage from a micro app:
/// ```dart
/// Column(
///   children: [
///     const Text('Accounts'),
///     const SizedBox(height: DsSpacing.sm),
///     DsListTile(title: 'Checking', onTap: openChecking),
///   ],
/// )
/// ```
abstract final class DsSpacing {
  /// Extra-extra-small step: 4.
  static const double xxs = 4;

  /// Extra-small step: 8.
  static const double xs = 8;

  /// Small step: 12.
  static const double sm = 12;

  /// Medium step, the default page padding: 16.
  static const double md = 16;

  /// Large step: 24.
  static const double lg = 24;

  /// Extra-large step: 32.
  static const double xl = 32;

  /// Extra-extra-large step: 48.
  static const double xxl = 48;
}

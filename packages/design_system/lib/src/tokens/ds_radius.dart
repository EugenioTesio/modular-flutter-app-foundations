/// Primitive corner-radius tokens, in logical pixels.
///
/// Use this when a custom shape needs rounded corners that match the
/// components: `BorderRadius.circular(DsRadius.md)`.
///
/// The scale is 4 · 8 · 16, plus [pill] for fully rounded ends.
///
/// Usage from a micro app:
/// ```dart
/// ClipRRect(
///   borderRadius: BorderRadius.circular(DsRadius.lg),
///   child: Image.asset('assets/promo.png'),
/// )
/// ```
abstract final class DsRadius {
  /// Small radius: 4.
  static const double sm = 4;

  /// Medium radius, used by buttons, fields, and cards: 8.
  static const double md = 8;

  /// Large radius: 16.
  static const double lg = 16;

  /// Radius large enough to round both ends of any control fully: 999.
  static const double pill = 999;
}

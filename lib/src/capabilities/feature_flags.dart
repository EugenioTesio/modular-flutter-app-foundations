import 'package:flutter/foundation.dart';

/// Definition of a typed feature flag and the value to use when no other
/// value is known.
///
/// Use this to declare each flag your micro app reads, as a `const` value of
/// one of its three variants: [BoolFeatureFlag], [StringFeatureFlag], or
/// [NumberFeatureFlag]. Read it with [FeatureFlags.valueOf].
///
/// This is **not** the flag's current value: it only names the flag and its
/// fallback.
///
/// Usage from a micro app:
/// ```dart
/// const newDashboard = BoolFeatureFlag(
///   key: 'accounts.new_dashboard',
///   defaultValue: false,
/// );
///
/// if (featureFlags.valueOf(newDashboard)) showNewDashboard();
/// ```
@immutable
sealed class FeatureFlag<T extends Object> {
  /// Creates a feature flag definition.
  ///
  /// Parameters:
  /// * [key] - The flag's key, following `<microAppId>.<flag_name>`.
  /// * [defaultValue] - The value to use when no other value is known.
  const FeatureFlag({required this.key, required this.defaultValue});

  /// Key of the flag, such as `accounts.new_dashboard`.
  final String key;

  /// Value [FeatureFlags.valueOf] returns when the flag is unknown, holds a
  /// value of the wrong kind, or the flag provider is unavailable.
  final T defaultValue;

  @override
  bool operator ==(Object other) =>
      other is FeatureFlag<T> &&
      other.runtimeType == runtimeType &&
      other.key == key &&
      other.defaultValue == defaultValue;

  @override
  int get hashCode => Object.hash(runtimeType, key, defaultValue);

  @override
  String toString() => '$runtimeType($key, defaultValue: $defaultValue)';
}

/// Definition of an on/off feature flag.
final class BoolFeatureFlag extends FeatureFlag<bool> {
  /// Creates an on/off feature flag definition.
  ///
  /// Parameters:
  /// * [key] - The flag's key, following `<microAppId>.<flag_name>`.
  /// * [defaultValue] - The value to use when no other value is known.
  const BoolFeatureFlag({required super.key, required super.defaultValue});
}

/// Definition of a text feature flag, such as a copy variant.
final class StringFeatureFlag extends FeatureFlag<String> {
  /// Creates a text feature flag definition.
  ///
  /// Parameters:
  /// * [key] - The flag's key, following `<microAppId>.<flag_name>`.
  /// * [defaultValue] - The value to use when no other value is known.
  const StringFeatureFlag({required super.key, required super.defaultValue});
}

/// Definition of a numeric feature flag, such as a limit.
final class NumberFeatureFlag extends FeatureFlag<num> {
  /// Creates a numeric feature flag definition.
  ///
  /// Parameters:
  /// * [key] - The flag's key, following `<microAppId>.<flag_name>`.
  /// * [defaultValue] - The value to use when no other value is known.
  const NumberFeatureFlag({required super.key, required super.defaultValue});
}

/// Contract that reads feature flags and remote configuration.
///
/// Use this to turn features on or off, or to tune values such as limits,
/// without a release. Declare each flag as a [FeatureFlag], read it with
/// [valueOf], and re-read it when [changes] emits.
///
/// Built-in: Core implements it on top of the host's flag provider. A no-op
/// implementation always returns each flag's default and never emits on
/// [changes].
///
/// Usage from a micro app:
/// ```dart
/// const maxItems = NumberFeatureFlag(
///   key: 'accounts.max_items',
///   defaultValue: 20,
/// );
///
/// final limit = featureFlags.valueOf(maxItems);
/// featureFlags.changes.listen((_) => reload(featureFlags.valueOf(maxItems)));
/// ```
abstract interface class FeatureFlags {
  /// Returns the current value of a flag.
  ///
  /// Parameters:
  /// * [flag] - The definition of the flag to read.
  ///
  /// Returns [FeatureFlag.defaultValue] when the flag is unknown, holds a
  /// value of the wrong kind, or the provider is unavailable. Never throws.
  T valueOf<T extends Object>(FeatureFlag<T> flag);

  /// Broadcast stream that emits after flag values are refreshed, for
  /// example after a remote configuration fetch.
  ///
  /// It carries no values: listeners re-read the flags they care about with
  /// [valueOf].
  Stream<void> get changes;
}

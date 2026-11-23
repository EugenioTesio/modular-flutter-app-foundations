/// @docImport '../capabilities/api_client.dart';
/// @docImport '../capabilities/key_value_store.dart';
/// @docImport '../exceptions/api_exception.dart';
/// @docImport '../routing/app_navigator.dart';
library;

import 'package:flutter/foundation.dart';

/// Outcome of an operation that can fail in an expected way: an [Ok] holding
/// a value of type [T], or an [Err] holding a failure of type [F].
///
/// Use this to handle the result of [ApiClient], [KeyValueStore], and
/// [AppNavigator] calls. Because the class is `sealed`, a `switch` over a
/// result is checked for exhaustiveness by the compiler, so no failure is
/// forgotten.
///
/// This is **not** thrown: expected failures, such as a timeout or an unknown
/// route, are values in the signature. Only programming mistakes throw.
///
/// Usage from a micro app:
/// ```dart
/// switch (await apiClient.get('/accounts/summary')) {
///   case Ok(:final value):
///     show(value.body);
///   case Err(failure: ApiException(type: ApiExceptionType.unauthorized)):
///     askToSignIn();
///   case Err(:final failure):
///     showError(failure.type);
/// }
/// ```
@immutable
sealed class Result<T, F> {
  const Result();
}

/// Successful [Result] holding the [value] the operation produced.
final class Ok<T, F> extends Result<T, F> {
  /// Creates a successful result.
  ///
  /// Parameters:
  /// * [value] - The value the operation produced.
  const Ok(this.value);

  /// Value the operation produced.
  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T, F> && other.value == value;

  @override
  int get hashCode => Object.hash(Ok, value);

  @override
  String toString() => 'Ok($value)';
}

/// Failed [Result] holding the [failure] that explains why.
final class Err<T, F> extends Result<T, F> {
  /// Creates a failed result.
  ///
  /// Parameters:
  /// * [failure] - The reason the operation failed, usually one of the
  ///   Foundations exceptions, such as an [ApiException].
  const Err(this.failure);

  /// Reason the operation failed, usually one of the Foundations exceptions.
  final F failure;

  @override
  bool operator ==(Object other) =>
      other is Err<T, F> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Err, failure);

  @override
  String toString() => 'Err($failure)';
}

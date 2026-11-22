import 'package:flutter/foundation.dart';

import 'inter_module_status.dart';

/// The result of every inter-module call.
///
/// [T] is `Map<String, Object?>` for data endpoints and `Widget` for UI
/// endpoints. Consumers decide what happened from [statusCode] and
/// [errorCode] alone; see `InterModuleStatusCode` and `InterModuleErrorCode`.
@immutable
final class InterModuleCommunicationResponse<T> {
  /// Creates a response with any status.
  ///
  /// Prefer [InterModuleCommunicationResponse.success] and
  /// [InterModuleCommunicationResponse.failure].
  const InterModuleCommunicationResponse({
    required this.statusCode,
    this.data,
    this.errorCode,
  });

  /// A success: status 200 with non-null [data].
  const InterModuleCommunicationResponse.success(T this.data)
    : statusCode = InterModuleStatusCode.ok,
      errorCode = null;

  /// A failure with [statusCode] outside 200–299, an optional [errorCode],
  /// and no data.
  const InterModuleCommunicationResponse.failure({
    required this.statusCode,
    this.errorCode,
  }) : data = null,
       assert(
         statusCode < 200 || statusCode >= 300,
         'A failure response needs a status outside 200–299.',
       );

  /// The outcome status, normally one of `InterModuleStatusCode`'s values.
  final int statusCode;

  /// The result map or UI element on success; null on any failure.
  final T? data;

  /// A machine-readable reason. Null on success. On failures produced by the
  /// implementation it is one of `InterModuleErrorCode`'s values.
  final String? errorCode;

  /// Whether [statusCode] is between 200 and 299.
  ///
  /// Any other status, including ones the contract does not list, is a
  /// failure.
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  @override
  String toString() =>
      'InterModuleCommunicationResponse($statusCode, '
      'errorCode: $errorCode, data: $data)';
}

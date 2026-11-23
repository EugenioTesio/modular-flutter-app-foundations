/// @docImport 'endpoint_provider.dart';
/// @docImport 'inter_module_communication.dart';
/// @docImport 'inter_module_value.dart';
library;

import 'package:flutter/foundation.dart';

import 'inter_module_status.dart';

/// Response that carries the outcome of every inter-module call.
///
/// Use this when a provider answers a call, or when a consumer reads the
/// result of [InterModuleCommunication.request] or
/// [InterModuleCommunication.getWidget]. [T] is `Map<String, Object?>` for
/// data endpoints and `Widget` for UI endpoints.
///
/// A consumer decides what happened from [statusCode] and [errorCode] alone,
/// using [InterModuleStatusCode] and [InterModuleErrorCode]; it reads [data]
/// only when [isSuccess] is true.
///
/// This is **not** an exception: inter-module calls never throw toward the
/// consumer, so every outcome, including a failing provider, arrives as a
/// response.
///
/// Usage from a provider:
/// ```dart
/// @override
/// Future<InterModuleCommunicationResponse<Map<String, Object?>>> handle(
///   Map<String, Object?> parameters,
/// ) async {
///   final id = parameters['id'];
///   if (id is! String || id.isEmpty) {
///     return const InterModuleCommunicationResponse.failure(
///       statusCode: InterModuleStatusCode.badRequest,
///       errorCode: 'invalid_id',
///     );
///   }
///   return InterModuleCommunicationResponse.success({'id': id, 'name': 'Savings'});
/// }
/// ```
///
/// Usage from a consumer:
/// ```dart
/// final response = await communication.request(endpoint: details);
/// if (response.isSuccess) {
///   show(response.data!);
/// } else if (response.errorCode == InterModuleErrorCode.unauthenticated) {
///   askToSignIn();
/// }
/// ```
@immutable
final class InterModuleCommunicationResponse<T> {
  /// Creates a response with any status.
  ///
  /// Prefer [InterModuleCommunicationResponse.success] and
  /// [InterModuleCommunicationResponse.failure], which keep the fields
  /// consistent.
  ///
  /// Parameters:
  /// * [statusCode] - The outcome status, normally one of the
  ///   [InterModuleStatusCode] values.
  /// * [data] - Optional result map or UI element; `null` on failures.
  /// * [errorCode] - Optional machine-readable reason; `null` on success.
  const InterModuleCommunicationResponse({
    required this.statusCode,
    this.data,
    this.errorCode,
  });

  /// Creates a success response with [InterModuleStatusCode.ok].
  ///
  /// Parameters:
  /// * [data] - The result map or UI element. A data endpoint's map follows
  ///   the payload rule (see [isInterModuleValue]).
  const InterModuleCommunicationResponse.success(T this.data)
    : statusCode = InterModuleStatusCode.ok,
      errorCode = null;

  /// Creates a failure response with no data.
  ///
  /// Parameters:
  /// * [statusCode] - The failure status, outside 200–299; an assertion
  ///   checks it in debug builds.
  /// * [errorCode] - Optional machine-readable reason, such as one of the
  ///   [InterModuleErrorCode] values or a provider's own code.
  const InterModuleCommunicationResponse.failure({
    required this.statusCode,
    this.errorCode,
  }) : data = null,
       assert(
         statusCode < 200 || statusCode >= 300,
         'A failure response needs a status outside 200–299.',
       );

  /// Outcome status, normally one of the [InterModuleStatusCode] values.
  final int statusCode;

  /// Optional result map or UI element, present only on success.
  ///
  /// A data endpoint's map follows the payload rule (see
  /// [isInterModuleValue]).
  final T? data;

  /// Optional machine-readable reason for a failure; `null` on success.
  ///
  /// On failures the implementation produces it is one of the
  /// [InterModuleErrorCode] values. Providers may use codes of their own.
  final String? errorCode;

  /// Whether [statusCode] is between 200 and 299.
  ///
  /// Any other status, including one the contract does not list, is a
  /// failure.
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  @override
  String toString() =>
      'InterModuleCommunicationResponse($statusCode, '
      'errorCode: $errorCode, data: $data)';
}

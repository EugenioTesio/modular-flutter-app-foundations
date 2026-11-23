/// @docImport '../capabilities/api_client.dart';
/// @docImport '../common/result.dart';
library;

import 'package:flutter/foundation.dart';

/// Category of an [ApiException].
///
/// Use this to decide how to react to a failed backend call, for example
/// asking the user to sign in on [unauthorized] or offering a retry on
/// [noConnectivity].
///
/// The categories fall into three groups: the connection, the backend's
/// answer, and the API client itself.
///
/// Built-in: Core's API client classifies every failed call as exactly one
/// type:
///
/// | Condition                                                      | Type               |
/// |----------------------------------------------------------------|--------------------|
/// | No connection or DNS failure                                   | [noConnectivity]   |
/// | The deadline was exceeded                                      | [timeout]          |
/// | The TLS handshake failed or the certificate was rejected       | [badCertificate]   |
/// | HTTP 401                                                       | [unauthorized]     |
/// | Any other HTTP 4xx                                             | [clientError]      |
/// | HTTP 5xx                                                       | [serverError]      |
/// | The request could not be built or encoded                      | [invalidRequest]   |
/// | The response could not be decoded, such as malformed JSON      | [invalidResponse]  |
/// | Any other error raised inside the client                       | [unknown]          |
enum ApiExceptionType {
  // Connection ---------------------------------------------------------------

  /// The backend could not be reached: no connection, or the address could
  /// not be resolved.
  noConnectivity,

  /// The backend did not answer in time.
  timeout,

  /// The secure connection failed: the TLS handshake failed or the server's
  /// certificate was rejected, for example by certificate pinning.
  badCertificate,

  // The backend's answer ----------------------------------------------------

  /// The session is missing or expired (HTTP 401).
  unauthorized,

  /// The backend rejected the request (HTTP 4xx other than 401). The status
  /// code and body are kept.
  clientError,

  /// The backend failed (HTTP 5xx). The status code and body are kept.
  serverError,

  // The API client itself ---------------------------------------------------

  /// The request could not be built or sent as described: the body is not
  /// JSON-encodable, or the path, a query parameter, or a header is invalid.
  /// No call reached the backend.
  invalidRequest,

  /// The backend answered, but the client could not decode the response:
  /// malformed JSON, an unexpected content type, or a body of the wrong
  /// shape. The status code is kept.
  invalidResponse,

  /// Any other error raised inside the client, so the caller still gets a
  /// typed exception instead of a vendor error.
  unknown,
}

/// Exception that explains why a backend call failed, in the application's
/// own vocabulary.
///
/// Use this to react to a failed [ApiClient] call by its [type], without ever
/// seeing a vendor error.
///
/// This is **not** thrown: [ApiClient.send] and its shortcuts return it
/// inside an [Err].
///
/// Usage from a micro app:
/// ```dart
/// switch (await apiClient.post('/transfers', body: transfer.toJson())) {
///   case Ok(:final value):
///     showReceipt(value.body);
///   case Err(failure: ApiException(type: ApiExceptionType.unauthorized)):
///     askToSignIn();
///   case Err(failure: ApiException(type: ApiExceptionType.clientError, :final body)):
///     showValidationErrors(body);
///   case Err(failure: ApiException(:final type)):
///     showRetry(type);
/// }
/// ```
@immutable
final class ApiException implements Exception {
  /// Creates an API exception.
  ///
  /// Parameters:
  /// * [type] - The category of the failure.
  /// * [statusCode] - Optional HTTP status, when the backend answered.
  /// * [body] - Optional decoded error body, when the backend sent one.
  const ApiException({required this.type, this.statusCode, this.body});

  /// Category of the failure.
  final ApiExceptionType type;

  /// Optional HTTP status code, present when the backend answered.
  ///
  /// It is set for [ApiExceptionType.unauthorized],
  /// [ApiExceptionType.clientError], [ApiExceptionType.serverError], and
  /// [ApiExceptionType.invalidResponse], and `null` when no answer arrived.
  final int? statusCode;

  /// Optional decoded error body, present when the backend sent one.
  ///
  /// It is compared with `==`.
  final Object? body;

  @override
  bool operator ==(Object other) =>
      other is ApiException &&
      other.type == type &&
      other.statusCode == statusCode &&
      other.body == body;

  @override
  int get hashCode => Object.hash(type, statusCode, body);

  @override
  String toString() =>
      'ApiException(${type.name}, statusCode: $statusCode, body: $body)';
}

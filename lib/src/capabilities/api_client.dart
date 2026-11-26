/// @docImport '../capabilities/session_context.dart';
library;

import 'package:flutter/foundation.dart';

import '../common/result.dart';
import '../exceptions/api_exception.dart';

/// HTTP method of an [ApiRequest].
///
/// Micro apps usually pick it implicitly through the [ApiClientShortcuts]
/// methods of the same name.
enum ApiMethod {
  /// Method that reads a resource.
  get,

  /// Method that creates a resource or triggers an action.
  post,

  /// Method that replaces a resource.
  put,

  /// Method that partially updates a resource.
  patch,

  /// Method that removes a resource.
  delete,
}

/// Value that describes one call to the application's backend.
///
/// Use this to call [ApiClient.send] directly, or to compare requests in
/// tests. Most micro app code builds it implicitly through
/// [ApiClientShortcuts].
///
/// This is **not** where credentials go: the implementation attaches them
/// and overrides any header of the same name.
///
/// Usage from a micro app:
/// ```dart
/// const request = ApiRequest(
///   method: ApiMethod.get,
///   path: '/accounts',
///   queryParams: {'page': '2'},
/// );
/// final result = await apiClient.send(request);
/// ```
@immutable
final class ApiRequest {
  /// Creates a backend request.
  ///
  /// Parameters:
  /// * [method] - The HTTP method.
  /// * [path] - The path relative to the backend's base address, starting
  ///   with `/`.
  /// * [queryParams] - Optional query parameters; defaults to empty.
  /// * [headers] - Optional extra headers; defaults to empty.
  /// * [body] - Optional JSON-encodable body; defaults to `null`.
  const ApiRequest({
    required this.method,
    required this.path,
    this.queryParams = const {},
    this.headers = const {},
    this.body,
  });

  /// HTTP method of the request.
  final ApiMethod method;

  /// Path relative to the backend's base address, such as
  /// `/accounts/summary`.
  ///
  /// The implementation resolves it against the base address of the current
  /// environment, so micro apps never hard-code a host.
  final String path;

  /// Query parameters appended to [path], compared by content.
  final Map<String, String> queryParams;

  /// Extra headers to send, compared by content.
  ///
  /// The implementation sets the credential headers itself and overrides any
  /// header of the same name supplied here.
  final Map<String, String> headers;

  /// Optional JSON-encodable body.
  ///
  /// A body that can't be encoded makes the call fail with
  /// [ApiExceptionType.invalidRequest]. It is compared with `==`, so two
  /// requests are equal only when their bodies are equal objects, such as the
  /// same `const` map.
  final Object? body;

  @override
  bool operator ==(Object other) =>
      other is ApiRequest &&
      other.method == method &&
      other.path == path &&
      mapEquals(other.queryParams, queryParams) &&
      mapEquals(other.headers, headers) &&
      other.body == body;

  @override
  int get hashCode => Object.hash(
    method,
    path,
    Object.hashAllUnordered(
      queryParams.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
    Object.hashAllUnordered(
      headers.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
    body,
  );

  /// Returns a description with the method, the path, and the names of the
  /// query parameters and headers, but none of their values and not the
  /// body, so printing a request never leaks credentials or personal data.
  @override
  String toString() =>
      'ApiRequest(${method.name} $path, '
      'queryParams: ${queryParams.keys.toList()}, '
      'headers: ${headers.keys.toList()}, '
      'body: ${body == null ? 'none' : 'present'})';
}

/// Value that holds a successful (2xx or 3xx) response from the backend.
///
/// Use this to read the [body] of a call that succeeded, and map it to your
/// micro app's own models.
///
/// This is **not** produced for failed calls: those produce an
/// [ApiException] instead.
@immutable
final class ApiResponse {
  /// Creates a backend response.
  ///
  /// Parameters:
  /// * [statusCode] - The HTTP status, between 200 and 399.
  /// * [body] - Optional decoded JSON body.
  /// * [headers] - Optional response headers; defaults to empty.
  const ApiResponse({
    required this.statusCode,
    this.body,
    this.headers = const {},
  });

  /// HTTP status code of the response, between 200 and 399.
  final int statusCode;

  /// Optional decoded JSON body: a [Map], a [List], or a JSON primitive.
  ///
  /// It is compared with `==`.
  final Object? body;

  /// Headers of the response, compared by content.
  final Map<String, String> headers;

  @override
  bool operator ==(Object other) =>
      other is ApiResponse &&
      other.statusCode == statusCode &&
      other.body == body &&
      mapEquals(other.headers, headers);

  @override
  int get hashCode => Object.hash(
    statusCode,
    body,
    Object.hashAllUnordered(
      headers.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
  );

  /// Returns a description with the status and the header names, but no
  /// header values and not the body, so printing a response never leaks
  /// credentials or personal data.
  @override
  String toString() =>
      'ApiResponse($statusCode, headers: ${headers.keys.toList()}, '
      'body: ${body == null ? 'none' : 'present'})';
}

/// Contract that is the only path from a micro app to the application's
/// backend.
///
/// Use this for every backend call your micro app makes, usually through the
/// [ApiClientShortcuts] methods. Handle the outcome with a `switch` over the
/// returned `Result`.
///
/// This is **not** where credentials are handled: the implementation
/// attaches the session's credentials, so micro apps never see, store, or
/// log tokens (they are not on [SessionContext] either).
///
/// Built-in: Core implements it, resolves each path against the current
/// environment's base address, and gives it to each micro app through its
/// context. In tests, implement [send] with a fake that returns canned
/// results; no network is involved.
///
/// Usage from a micro app:
/// ```dart
/// final result = await apiClient.get(
///   '/accounts',
///   queryParams: {'page': '2'},
/// );
/// final accounts = switch (result) {
///   Ok(:final value) => parseAccounts(value.body),
///   Err() => const <Account>[],
/// };
/// ```
abstract interface class ApiClient {
  /// Sends a request to the backend.
  ///
  /// Parameters:
  /// * [request] - The method, path, query parameters, headers, and body.
  ///
  /// Returns an [Ok] holding the [ApiResponse], or an [Err] holding an
  /// [ApiException] with exactly one [ApiExceptionType], following the
  /// mapping documented on [ApiExceptionType]. Never throws.
  Future<Result<ApiResponse, ApiException>> send(ApiRequest request);
}

/// Shortcuts that build an [ApiRequest] for each [ApiMethod] and pass it to
/// [ApiClient.send].
///
/// Built-in: fakes only need to implement [ApiClient.send]; these methods
/// work on any implementation.
extension ApiClientShortcuts on ApiClient {
  /// Sends a `GET` request.
  ///
  /// Parameters:
  /// * [path] - The path relative to the backend's base address.
  /// * [queryParams] - Optional query parameters; defaults to empty.
  /// * [headers] - Optional extra headers; defaults to empty.
  Future<Result<ApiResponse, ApiException>> get(
    String path, {
    Map<String, String> queryParams = const {},
    Map<String, String> headers = const {},
  }) => send(
    ApiRequest(
      method: ApiMethod.get,
      path: path,
      queryParams: queryParams,
      headers: headers,
    ),
  );

  /// Sends a `POST` request.
  ///
  /// Parameters:
  /// * [path] - The path relative to the backend's base address.
  /// * [body] - Optional JSON-encodable body.
  /// * [queryParams] - Optional query parameters; defaults to empty.
  /// * [headers] - Optional extra headers; defaults to empty.
  Future<Result<ApiResponse, ApiException>> post(
    String path, {
    Object? body,
    Map<String, String> queryParams = const {},
    Map<String, String> headers = const {},
  }) => send(
    ApiRequest(
      method: ApiMethod.post,
      path: path,
      queryParams: queryParams,
      headers: headers,
      body: body,
    ),
  );

  /// Sends a `PUT` request.
  ///
  /// Parameters:
  /// * [path] - The path relative to the backend's base address.
  /// * [body] - Optional JSON-encodable body.
  /// * [queryParams] - Optional query parameters; defaults to empty.
  /// * [headers] - Optional extra headers; defaults to empty.
  Future<Result<ApiResponse, ApiException>> put(
    String path, {
    Object? body,
    Map<String, String> queryParams = const {},
    Map<String, String> headers = const {},
  }) => send(
    ApiRequest(
      method: ApiMethod.put,
      path: path,
      queryParams: queryParams,
      headers: headers,
      body: body,
    ),
  );

  /// Sends a `PATCH` request.
  ///
  /// Parameters:
  /// * [path] - The path relative to the backend's base address.
  /// * [body] - Optional JSON-encodable body.
  /// * [queryParams] - Optional query parameters; defaults to empty.
  /// * [headers] - Optional extra headers; defaults to empty.
  Future<Result<ApiResponse, ApiException>> patch(
    String path, {
    Object? body,
    Map<String, String> queryParams = const {},
    Map<String, String> headers = const {},
  }) => send(
    ApiRequest(
      method: ApiMethod.patch,
      path: path,
      queryParams: queryParams,
      headers: headers,
      body: body,
    ),
  );

  /// Sends a `DELETE` request.
  ///
  /// Parameters:
  /// * [path] - The path relative to the backend's base address.
  /// * [queryParams] - Optional query parameters; defaults to empty.
  /// * [headers] - Optional extra headers; defaults to empty.
  Future<Result<ApiResponse, ApiException>> delete(
    String path, {
    Map<String, String> queryParams = const {},
    Map<String, String> headers = const {},
  }) => send(
    ApiRequest(
      method: ApiMethod.delete,
      path: path,
      queryParams: queryParams,
      headers: headers,
    ),
  );
}

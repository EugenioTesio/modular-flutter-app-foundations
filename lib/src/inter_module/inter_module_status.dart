/// The four inter-module statuses.
///
/// They borrow the meaning of HTTP status codes, but they are application
/// statuses for in-process calls, not network responses.
abstract final class InterModuleStatusCode {
  /// Success: the response data holds the result map or the UI element.
  static const int ok = 200;

  /// A required parameter is missing or null, the provider rejected a value,
  /// or the provider refused access. The error code tells the cases apart.
  static const int badRequest = 400;

  /// The endpoint is not registered, or the provider reports that the item
  /// does not exist. The error code tells the cases apart.
  static const int notFound = 404;

  /// The handler or factory failed unexpectedly. No details are exposed.
  static const int internalError = 500;
}

/// The shared error codes that every implementation and provider uses.
///
/// Providers may also return their own codes, such as `invalid_id` or
/// `details_not_found`.
abstract final class InterModuleErrorCode {
  /// 400, produced by the implementation before the provider is called: a
  /// required parameter is absent or null.
  static const String missingRequiredParameters = 'missing_required_parameters';

  /// 404, produced by the implementation: no provider is registered at the
  /// address for this type of endpoint.
  static const String endpointNotRegistered = 'endpoint_not_registered';

  /// 400, produced by a provider: the user is not signed in.
  static const String unauthenticated = 'unauthenticated';

  /// 400, produced by a provider: the user lacks the needed permission.
  static const String forbidden = 'forbidden';
}

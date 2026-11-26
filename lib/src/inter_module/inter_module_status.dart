/// @docImport 'endpoint_provider.dart';
/// @docImport 'inter_module_communication.dart';
/// @docImport 'inter_module_response.dart';
library;

/// Constants for the four statuses an [InterModuleCommunicationResponse] can
/// carry.
///
/// Use this when a provider builds a failure or a consumer branches on the
/// outcome of a call. A consumer treats any status outside 200–299 as a
/// failure, and tells failures apart with
/// [InterModuleCommunicationResponse.errorCode].
///
/// This is **not** an HTTP status: the values borrow HTTP's meaning, but they
/// describe in-process calls between micro apps. No other status is
/// published.
///
/// Usage from a consumer:
/// ```dart
/// final response = await communication.request(endpoint: details);
/// switch (response.statusCode) {
///   case InterModuleStatusCode.ok:
///     show(response.data!);
///   case InterModuleStatusCode.notFound:
///     showNotFound();
///   default:
///     showError(response.errorCode);
/// }
/// ```
abstract final class InterModuleStatusCode {
  /// Status of a success: [InterModuleCommunicationResponse.data] holds the
  /// result map or the UI element.
  static const int ok = 200;

  /// Status of a call that was rejected.
  ///
  /// A required parameter is missing or `null`, the provider rejected a
  /// value, or the provider refused access. The error code tells the cases
  /// apart, for example [InterModuleErrorCode.missingRequiredParameters],
  /// [InterModuleErrorCode.unauthenticated], or a provider's own code such as
  /// `invalid_id`.
  static const int badRequest = 400;

  /// Status of a call whose endpoint or item does not exist.
  ///
  /// The error code tells the cases apart:
  /// [InterModuleErrorCode.endpointNotRegistered], or a provider's own code
  /// such as `details_not_found`.
  static const int notFound = 404;

  /// Status of a call whose handler or widget factory failed unexpectedly.
  ///
  /// No exception details reach the consumer: the error code never contains
  /// the exception's text.
  static const int internalError = 500;
}

/// Constants for the error codes that every [InterModuleCommunication]
/// implementation and every provider shares.
///
/// Use this when a provider refuses a call, or when a consumer needs to react
/// to a specific reason, such as asking the user to sign in.
///
/// Providers may also return codes of their own, such as `invalid_id` or
/// `details_not_found`, and document them next to their endpoint.
///
/// Usage from a provider:
/// ```dart
/// if (session.current is Unauthenticated) {
///   return const InterModuleCommunicationResponse.failure(
///     statusCode: InterModuleStatusCode.badRequest,
///     errorCode: InterModuleErrorCode.unauthenticated,
///   );
/// }
/// ```
abstract final class InterModuleErrorCode {
  /// Code of a call whose required parameter is absent or `null`.
  ///
  /// Sent with [InterModuleStatusCode.badRequest] by the implementation,
  /// before the provider is called.
  static const String missingRequiredParameters = 'missing_required_parameters';

  /// Code of a call to an address with no provider for its [EndpointType].
  ///
  /// Sent with [InterModuleStatusCode.notFound] by the implementation.
  static const String endpointNotRegistered = 'endpoint_not_registered';

  /// Code of a call the provider refuses because no user is signed in.
  ///
  /// Sent with [InterModuleStatusCode.badRequest] by a
  /// [DataEndpointProvider] or [WidgetEndpointProvider].
  static const String unauthenticated = 'unauthenticated';

  /// Code of a call the provider refuses because the signed-in user is not
  /// allowed to make it.
  ///
  /// Sent with [InterModuleStatusCode.badRequest] by a provider. The
  /// providing micro app decides what "allowed" means, usually through its
  /// own backend.
  static const String forbidden = 'forbidden';
}

import 'package:foundations/foundations.dart';

/// Whether the current user may see Module B's details.
enum ModuleBAccess {
  /// Signed in and allowed.
  granted,

  /// Not signed in.
  signedOut,

  /// Signed in, but without the needed permission.
  forbidden,
}

/// Module B owns `/module-b/v1/details`: the meaning of `id` and the response
/// schema `{id, name}`.
class ModuleBDetailsProvider implements DataEndpointProvider {
  /// Creates the provider. [access] reports the current user's access; a real
  /// micro app reads it from its session and permissions contracts.
  ModuleBDetailsProvider({required this.access});

  /// The current user's access to the details.
  final ModuleBAccess Function() access;

  @override
  InterModuleEndpoint get endpoint => const InterModuleEndpoint(
    url: '/module-b/v1/details',
    requiredParameters: {'id'},
  );

  @override
  Future<InterModuleCommunicationResponse<Map<String, Object?>>> handle(
    Map<String, Object?> parameters,
  ) async {
    switch (access()) {
      case ModuleBAccess.signedOut:
        return const InterModuleCommunicationResponse.failure(
          statusCode: InterModuleStatusCode.badRequest,
          errorCode: InterModuleErrorCode.unauthenticated,
        );
      case ModuleBAccess.forbidden:
        return const InterModuleCommunicationResponse.failure(
          statusCode: InterModuleStatusCode.badRequest,
          errorCode: InterModuleErrorCode.forbidden,
        );
      case ModuleBAccess.granted:
        break;
    }

    final id = parameters['id'];
    if (id is! String || id.trim().isEmpty) {
      return const InterModuleCommunicationResponse.failure(
        statusCode: InterModuleStatusCode.badRequest,
        errorCode: 'invalid_id',
      );
    }
    // Simulates an unexpected failure inside the provider.
    if (id == 'boom') throw StateError('Module B storage is unavailable');
    if (id != '123') {
      return const InterModuleCommunicationResponse.failure(
        statusCode: InterModuleStatusCode.notFound,
        errorCode: 'details_not_found',
      );
    }
    return InterModuleCommunicationResponse.success({
      'id': id,
      'name': 'Example details',
    });
  }
}

import 'package:foundations/foundations.dart';

/// Module B's details endpoint, as in the reference article.
class ModuleBDetailsProvider implements DataEndpointProvider {
  @override
  InterModuleEndpoint get endpoint => const InterModuleEndpoint(
    url: '/module-b/v1/details',
    requiredParameters: {'id'},
  );

  @override
  Future<InterModuleCommunicationResponse<Map<String, Object?>>> handle(
    Map<String, Object?> parameters,
  ) async {
    final id = parameters['id'];
    if (id is! String || id.trim().isEmpty) {
      return const InterModuleCommunicationResponse.failure(
        statusCode: InterModuleStatusCode.badRequest,
        errorCode: 'invalid_id',
      );
    }
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

/// A second Module B endpoint with no required parameters.
class ModuleBSummaryProvider implements DataEndpointProvider {
  @override
  InterModuleEndpoint get endpoint =>
      const InterModuleEndpoint(url: '/module-b/v1/summary');

  @override
  Future<InterModuleCommunicationResponse<Map<String, Object?>>> handle(
    Map<String, Object?> parameters,
  ) async => const InterModuleCommunicationResponse.success({'count': 1});
}

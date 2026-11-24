import 'package:flutter/widgets.dart';
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

/// Cards owns `/cards/v1/home-banner`: a banner whose card Cards chooses
/// itself, so callers send no parameters. The banner loads its own data after
/// it is placed.
class CardsHomeBannerProvider implements WidgetEndpointProvider {
  /// Creates the provider.
  const CardsHomeBannerProvider();

  @override
  InterModuleEndpoint get endpoint =>
      const InterModuleEndpoint(url: '/cards/v1/home-banner');

  @override
  InterModuleCommunicationResponse<Widget> build(
    Map<String, Object?> parameters,
  ) => const InterModuleCommunicationResponse.success(
    Text('Primary card', key: ValueKey('cards.home-banner')),
  );
}

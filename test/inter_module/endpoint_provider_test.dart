// Feature: Endpoint providers and bulk registration, for data and UI
// endpoints (FR-046, FR-047, SC-014; User Stories 1 and 5).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';

import '../support/sample_providers.dart';

/// Records every registration it receives.
class _RecordingCommunication implements InterModuleCommunication {
  final dataRegistrations = <InterModuleEndpoint>[];
  final widgetRegistrations = <InterModuleEndpoint>[];
  final _urls = <String>{};

  @override
  void register({
    required InterModuleEndpoint endpoint,
    required InterModuleHandler handler,
  }) {
    if (!_urls.add('data:${endpoint.url}')) {
      throw DuplicateEndpointException(
        url: endpoint.url,
        type: EndpointType.data,
      );
    }
    dataRegistrations.add(endpoint);
  }

  @override
  void registerWidget({
    required InterModuleEndpoint endpoint,
    required InterModuleWidgetFactory factory,
  }) {
    widgetRegistrations.add(endpoint);
  }

  @override
  Future<InterModuleCommunicationResponse<Map<String, Object?>>> request({
    required InterModuleEndpoint endpoint,
  }) => throw UnimplementedError();

  @override
  InterModuleCommunicationResponse<Widget> getWidget({
    required InterModuleEndpoint endpoint,
  }) => throw UnimplementedError();

  @override
  bool isRegistered({required String url, required EndpointType type}) =>
      throw UnimplementedError();
}

void main() {
  group('Given the Module B details provider', () {
    final provider = ModuleBDetailsProvider();

    test(
      'When it is called directly with id "123", '
      'Then it returns 200 with the details and no communication is needed',
      () async {
        // When
        final response = await provider.handle({'id': '123'});

        // Then
        expect(response.statusCode, 200);
        expect(response.data, {'id': '123', 'name': 'Example details'});
      },
    );

    test('When it is called directly with an empty id, '
        'Then it returns 400 invalid_id', () async {
      // When
      final response = await provider.handle({'id': ''});

      // Then
      expect(response.statusCode, 400);
      expect(response.errorCode, 'invalid_id');
    });

    test('When it is called directly with an unknown id, '
        'Then it returns 404 details_not_found', () async {
      // When
      final response = await provider.handle({'id': '999'});

      // Then
      expect(response.statusCode, 404);
      expect(response.errorCode, 'details_not_found');
    });

    test('When its endpoint is read, '
        'Then it declares its url and its required parameter', () {
      // When
      final endpoint = provider.endpoint;

      // Then
      expect(endpoint.url, '/module-b/v1/details');
      expect(endpoint.requiredParameters, {'id'});
    });
  });

  group('Given the Cards home-banner provider', () {
    const provider = CardsHomeBannerProvider();

    test('When build is called directly with no parameters, '
        'Then it returns 200 with a widget, synchronously', () {
      // When
      final response = provider.build(const {});

      // Then
      expect(response.statusCode, InterModuleStatusCode.ok);
      expect(response.data, isA<Widget>());
      expect(response.data!.key, const ValueKey('cards.home-banner'));
    });

    test('When its endpoint is read, '
        'Then it declares its url and no required parameters', () {
      // When
      final endpoint = provider.endpoint;

      // Then
      expect(endpoint.url, '/cards/v1/home-banner');
      expect(endpoint.requiredParameters, isEmpty);
    });
  });

  group('Given a communication that records registrations', () {
    late _RecordingCommunication communication;

    setUp(() => communication = _RecordingCommunication());

    test('When data providers are registered in bulk, '
        'Then each provider endpoint is registered as a data endpoint', () {
      // Given
      final providers = [ModuleBDetailsProvider(), ModuleBSummaryProvider()];

      // When
      communication.registerProviders(data: providers);

      // Then
      expect(communication.dataRegistrations.map((e) => e.url), [
        '/module-b/v1/details',
        '/module-b/v1/summary',
      ]);
      expect(communication.widgetRegistrations, isEmpty);
    });

    test('When two data providers share a url, '
        'Then the DuplicateEndpointException propagates', () {
      // Given
      final providers = [ModuleBDetailsProvider(), ModuleBDetailsProvider()];

      // When
      void registerAll() => communication.registerProviders(data: providers);

      // Then
      expect(
        registerAll,
        throwsA(
          isA<DuplicateEndpointException>()
              .having((e) => e.url, 'url', '/module-b/v1/details')
              .having((e) => e.type, 'type', EndpointType.data),
        ),
      );
    });

    test('When UI providers are registered in bulk, '
        'Then each provider endpoint is registered as a UI endpoint', () {
      // Given
      const widgets = [CardsHomeBannerProvider()];

      // When
      communication.registerProviders(
        data: [ModuleBDetailsProvider()],
        widgets: widgets,
      );

      // Then
      expect(communication.widgetRegistrations.map((e) => e.url), [
        '/cards/v1/home-banner',
      ]);
      expect(communication.dataRegistrations.map((e) => e.url), [
        '/module-b/v1/details',
      ]);
    });
  });
}

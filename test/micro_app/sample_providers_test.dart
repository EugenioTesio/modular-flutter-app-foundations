// Feature: Endpoint providers are unit-tested on their own, by calling handle
// or build directly with no communication implementation (SC-014).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';

import '../support/fakes.dart';
import '../support/sample_micro_apps.dart';

void main() {
  group('Given the Accounts balance provider over a fake API client', () {
    test('When handle gets a known account, '
        'Then it returns the balance the API returned', () async {
      // Given
      final apiClient = RecordingApiClient(
        respond: (request) =>
            const Ok(ApiResponse(statusCode: 200, body: 1250)),
      );
      final provider = AccountsBalanceProvider(apiClient);

      // When
      final response = await provider.handle({'accountId': 'a1'});

      // Then
      expect(response.statusCode, InterModuleStatusCode.ok);
      expect(response.data, {'accountId': 'a1', 'balance': 1250});
      expect(apiClient.requests.single.path, '/accounts/a1/balance');
    });

    test('When handle gets an account the API does not know, '
        'Then it returns notFound with account_not_found', () async {
      // Given
      final provider = AccountsBalanceProvider(
        RecordingApiClient(
          respond: (request) => const Err(
            ApiException(type: ApiExceptionType.clientError, statusCode: 404),
          ),
        ),
      );

      // When
      final response = await provider.handle({'accountId': 'missing'});

      // Then
      expect(response.statusCode, InterModuleStatusCode.notFound);
      expect(response.errorCode, 'account_not_found');
    });

    test('When the API fails otherwise, '
        'Then handle returns internalError with balance_unavailable', () async {
      // Given
      final provider = AccountsBalanceProvider(
        RecordingApiClient(
          respond: (request) =>
              const Err(ApiException(type: ApiExceptionType.timeout)),
        ),
      );

      // When
      final response = await provider.handle({'accountId': 'a1'});

      // Then
      expect(response.statusCode, InterModuleStatusCode.internalError);
      expect(response.errorCode, 'balance_unavailable');
    });

    test('When handle gets an empty account id, '
        'Then it returns badRequest without calling the API', () async {
      // Given
      final apiClient = RecordingApiClient();
      final provider = AccountsBalanceProvider(apiClient);

      // When
      final response = await provider.handle({'accountId': ''});

      // Then
      expect(response.statusCode, InterModuleStatusCode.badRequest);
      expect(response.errorCode, 'invalid_account_id');
      expect(apiClient.requests, isEmpty);
    });

    test('When its endpoint is read, '
        'Then it requires accountId at /accounts/v1/balance', () {
      // Given
      final provider = AccountsBalanceProvider(RecordingApiClient());

      // When
      final endpoint = provider.endpoint;

      // Then
      expect(endpoint.url, '/accounts/v1/balance');
      expect(endpoint.requiredParameters, {'accountId'});
    });
  });

  group('Given the Accounts balance card provider', () {
    const provider = AccountsBalanceCardProvider();

    testWidgets('When build gets an account id, '
        'Then the widget it returns shows that account', (tester) async {
      // Given
      const parameters = {'accountId': 'a1'};

      // When
      final response = provider.build(parameters);

      // Then
      expect(response.isSuccess, isTrue);
      await tester.pumpWidget(MaterialApp(home: response.data));
      expect(find.text('Balance of a1'), findsOneWidget);
    });

    test('When build gets no account id, '
        'Then it returns badRequest and no widget', () {
      // Given
      const parameters = <String, Object?>{};

      // When
      final response = provider.build(parameters);

      // Then
      expect(response.statusCode, InterModuleStatusCode.badRequest);
      expect(response.errorCode, 'invalid_account_id');
      expect(response.data, isNull);
    });
  });

  group('Given the Transfers draft-count provider over its own store', () {
    test('When no draft is saved, Then handle returns a count of 0', () async {
      // Given
      final store = InMemoryKeyValueStore(declaredKeys: {'transfers.draft'});
      final provider = TransfersDraftCountProvider(store);

      // When
      final response = await provider.handle(const {});

      // Then
      expect(response.data, {'count': 0});
    });

    test('When a draft is saved, Then handle returns a count of 1', () async {
      // Given
      final store = InMemoryKeyValueStore(
        declaredKeys: {'transfers.draft'},
        entries: {'transfers.draft': 'd1'},
      );
      final provider = TransfersDraftCountProvider(store);

      // When
      final response = await provider.handle(const {});

      // Then
      expect(response.data, {'count': 1});
    });

    test('When the store cannot be read, '
        'Then handle returns internalError with storage_unavailable', () async {
      // Given: a store that does not allow the draft key.
      final provider = TransfersDraftCountProvider(
        InMemoryKeyValueStore(declaredKeys: const {}),
      );

      // When
      final response = await provider.handle(const {});

      // Then
      expect(response.statusCode, InterModuleStatusCode.internalError);
      expect(response.errorCode, 'storage_unavailable');
    });
  });
}

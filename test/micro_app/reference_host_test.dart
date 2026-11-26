// Feature: Any host integrates any micro app the same way (US3 acceptance
// scenarios 1–9, SC-016; contracts/micro-app.md, "Host sequence";
// data-model.md MicroApp.storedKeys and "Stored key").
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';

import '../support/fakes.dart';
import '../support/reference_host.dart';
import '../support/sample_micro_apps.dart';

const _signedIn = Authenticated(UserIdentity(userId: 'user-1'));

ReferenceHost _host(
  List<MicroApp> microApps, {
  AppLogger? logger,
  Map<String, String>? storage,
}) => ReferenceHost(
  microApps: microApps,
  services: ReferenceHostServices.fakes(
    session: FakeSessionContext(_signedIn),
    logger: logger,
  ),
  storage: storage,
);

Matcher _startupFailureNaming(List<String> culprits) => throwsA(
  isA<ModularAppStartupException>().having(
    (exception) => exception.message,
    'message',
    allOf([for (final culprit in culprits) contains(culprit)]),
  ),
);

void main() {
  // The router built in step 6 needs the binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Given micro apps whose declarations collide', () {
    test('When two micro apps share an id, '
        'Then startup stops naming the id before any initialize', () async {
      // Given
      final journal = <String>[];
      final host = _host([
        SampleAccountsMicroApp(journal: journal),
        SampleAccountsMicroApp(journal: journal),
      ]);

      // When
      final starting = host.start();

      // Then
      await expectLater(starting, _startupFailureNaming(['"accounts"']));
      expect(journal, isEmpty);
    });

    test('When Accounts and Transfers both declare session_cache, '
        'Then startup stops naming the key and both micro apps', () async {
      // Given
      final host = _host([
        SampleAccountsMicroApp(extraStoredKeys: {'session_cache'}),
        SampleTransfersMicroApp(extraStoredKeys: {'session_cache'}),
      ]);

      // When
      final starting = host.start();

      // Then
      await expectLater(
        starting,
        _startupFailureNaming(['session_cache', '"accounts"', '"transfers"']),
      );
    });

    test('When two routes share a full path, '
        'Then startup stops naming the path', () async {
      // Given
      final host = _host([
        SampleAccountsMicroApp(
          extraRoutes: [
            MicroAppRoute(
              path: '/accounts/picker',
              builder: (context, parameters, body) =>
                  throw UnimplementedError(),
            ),
          ],
        ),
      ]);

      // When
      final starting = host.start();

      // Then
      await expectLater(starting, _startupFailureNaming(['/accounts/picker']));
    });

    test('When two micro apps declare the same provider URL, '
        'Then startup stops with DuplicateEndpointException', () async {
      // Given
      final host = _host([
        SampleAccountsMicroApp(),
        SampleMicroApp(
          id: 'impostor',
          data: (context) => [AccountsBalanceProvider(context.apiClient)],
        ),
      ]);

      // When
      final starting = host.start();

      // Then
      await expectLater(
        starting,
        throwsA(
          isA<DuplicateEndpointException>()
              .having((e) => e.url, 'url', '/accounts/v1/balance')
              .having((e) => e.type, 'type', EndpointType.data),
        ),
      );
    });
  });

  group('Given the Home, Auth, Accounts, and Transfers micro apps', () {
    late List<String> journal;
    late Map<String, String> storage;
    late SampleAccountsMicroApp accounts;
    late SampleTransfersMicroApp transfers;
    late ReferenceHost host;

    setUp(() async {
      journal = [];
      storage = {};
      accounts = SampleAccountsMicroApp(journal: journal);
      transfers = SampleTransfersMicroApp(journal: journal);
      host = _host([
        SampleMicroApps.home(journal: journal),
        SampleMicroApps.auth(journal: journal),
        accounts,
        transfers,
      ], storage: storage);
      await host.start();
    });

    tearDown(() => host.dispose());

    test('When the host starts, '
        'Then the micro apps initialize once each, in order', () {
      // Given: the started host.

      // When
      final events = journal;

      // Then
      expect(events, [
        'home.initialize',
        'auth.initialize',
        'accounts.initialize',
        'transfers.initialize',
      ]);
    });

    test('When the host starts, '
        'Then each micro app gets its own context with shared services', () {
      // Given: the started host.

      // When
      final accountsContext = accounts.context;
      final transfersContext = transfers.context;

      // Then
      expect(accountsContext, isNot(same(transfersContext)));
      expect(
        accountsContext.keyValueStore,
        isNot(same(transfersContext.keyValueStore)),
      );
      expect(
        accountsContext.communication,
        same(transfersContext.communication),
      );
      expect(accountsContext.session, same(transfersContext.session));
      expect(accountsContext.navigator, same(transfersContext.navigator));
    });

    test(
      'When Accounts writes Transfers\' key transfers.draft, '
      'Then it gets undeclaredKey and Transfers\' value is unchanged',
      () async {
        // Given
        await transfers.context.keyValueStore.write('transfers.draft', 'd1');

        // When
        final result = await accounts.context.keyValueStore.write(
          'transfers.draft',
          'overwritten',
        );

        // Then
        expect(
          result,
          const Err<void, StorageException>(
            StorageException(
              type: StorageExceptionType.undeclaredKey,
              key: 'transfers.draft',
            ),
          ),
        );
        expect(
          await transfers.context.keyValueStore.read('transfers.draft'),
          const Ok<String?, StorageException>('d1'),
        );
        expect(storage, {'transfers.draft': 'd1'});
      },
    );

    test('When Accounts uses its secure store on an undeclared key, '
        'Then it gets undeclaredKey too', () async {
      // Given
      final secure = accounts.context.secureKeyValueStore;

      // When
      final result = await secure.read('transfers.draft');

      // Then
      expect(
        result,
        const Err<String?, StorageException>(
          StorageException(
            type: StorageExceptionType.undeclaredKey,
            key: 'transfers.draft',
          ),
        ),
      );
    });

    test('When the host has started, '
        'Then isRegistered is true for every declared provider', () {
      // Given
      final communication = accounts.context.communication;

      // When
      final registered = {
        for (final (url, type) in const [
          ('/accounts/v1/balance', EndpointType.data),
          ('/accounts/v1/balance-card', EndpointType.widget),
          ('/transfers/v1/draft-count', EndpointType.data),
        ])
          url: communication.isRegistered(url: url, type: type),
      };

      // Then
      expect(registered.values, everyElement(isTrue));
      expect(
        communication.isRegistered(
          url: '/accounts/v1/balance',
          type: EndpointType.widget,
        ),
        isFalse,
      );
    });

    test('When a module requests a registered endpoint, '
        'Then the owning micro app answers it', () async {
      // Given
      await transfers.context.keyValueStore.write('transfers.draft', 'd1');

      // When
      final response = await accounts.context.communication.request(
        endpoint: const InterModuleEndpoint(url: '/transfers/v1/draft-count'),
      );

      // Then
      expect(response.statusCode, InterModuleStatusCode.ok);
      expect(response.data, {'count': 1});
    });

    test('When the host has started, '
        'Then routes and localization delegates were collected', () {
      // Given: the started host.

      // When
      final owners = {
        for (final path in const [
          '/home',
          '/auth/sign-in',
          '/accounts/details/:accountId',
          '/accounts/tabs/history',
          '/transfers',
        ])
          path: host.container.microAppIdOf(path),
      };

      // Then
      expect(owners, {
        '/home': 'home',
        '/auth/sign-in': 'auth',
        '/accounts/details/:accountId': 'accounts',
        '/accounts/tabs/history': 'accounts',
        '/transfers': 'transfers',
      });
      expect(host.localizationsDelegates, hasLength(4));
      expect(host.navigator.target, same(host.router));
    });

    test('When the host is torn down, '
        'Then the micro apps dispose in reverse order', () async {
      // Given
      journal.clear();

      // When
      final failures = await host.dispose();

      // Then
      expect(failures, isEmpty);
      expect(journal, [
        'transfers.dispose',
        'accounts.dispose',
        'auth.dispose',
        'home.dispose',
      ]);
    });
  });

  group('Given a micro app whose teardown throws', () {
    test('When the host is torn down, '
        'Then the failure is reported and the others still dispose', () async {
      // Given
      final journal = <String>[];
      final logger = RecordingAppLogger();
      final host = _host([
        SampleMicroApps.home(journal: journal),
        SampleAccountsMicroApp(journal: journal, failOnDispose: true),
        SampleTransfersMicroApp(journal: journal),
      ], logger: logger);
      await host.start();
      journal.clear();

      // When
      final failures = await host.dispose();

      // Then
      expect(journal, [
        'transfers.dispose',
        'accounts.dispose',
        'home.dispose',
      ]);
      expect(failures.map((failure) => failure.$1), ['accounts']);
      final error = logger.entries.singleWhere(
        (entry) => entry.level == LogLevel.error,
      );
      expect(error.context, {'microAppId': 'accounts'});
    });
  });
}

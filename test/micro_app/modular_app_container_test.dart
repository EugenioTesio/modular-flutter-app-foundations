// Feature: A host starts its micro apps through ModularAppContainer, which
// gathers what the application needs as the micro apps declared it
// (contracts/micro-app.md, "Host sequence"; data-model.md MicroApp.storedKeys
// and "Stored key").
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';

import '../support/fakes.dart';
import '../support/reference_inter_module_communication.dart';
import '../support/sample_micro_apps.dart';

/// A micro app whose initialize throws, after recording the attempt.
final class _FailingMicroApp extends SampleMicroApp {
  _FailingMicroApp({required super.id, super.journal});

  @override
  Future<void> initialize(MicroAppContext context) async {
    journal.add('$id.initialize');
    throw StateError('$id could not start');
  }
}

/// A delegate that only needs to be told apart from another one.
final class _NamedDelegate extends LocalizationsDelegate<Object?> {
  const _NamedDelegate(this.name);

  final String name;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<Object?> load(Locale locale) async => name;

  @override
  bool shouldReload(_NamedDelegate old) => false;
}

/// A micro app that declares its own localization delegates.
final class _LocalizedMicroApp extends SampleMicroApp {
  _LocalizedMicroApp({required super.id, required this.delegates});

  final List<LocalizationsDelegate<Object?>> delegates;

  @override
  List<LocalizationsDelegate<Object?>> get localizationsDelegates => delegates;
}

/// The host's data endpoint `/app/v1/version`.
final class _AppVersionProvider implements DataEndpointProvider {
  const _AppVersionProvider();

  @override
  InterModuleEndpoint get endpoint =>
      const InterModuleEndpoint(url: '/app/v1/version');

  @override
  Future<InterModuleCommunicationResponse<Map<String, Object?>>> handle(
    Map<String, Object?> parameters,
  ) async => const InterModuleCommunicationResponse.success({'version': '1'});
}

/// The host's widget endpoint `/app/v1/banner`.
final class _AppBannerProvider implements WidgetEndpointProvider {
  const _AppBannerProvider();

  @override
  InterModuleEndpoint get endpoint =>
      const InterModuleEndpoint(url: '/app/v1/banner');

  @override
  InterModuleCommunicationResponse<Widget> build(
    Map<String, Object?> parameters,
  ) => const InterModuleCommunicationResponse.success(SizedBox());
}

Matcher _startupFailure(
  ModularAppStartupExceptionType type,
  List<String> culprits,
) => throwsA(
  isA<ModularAppStartupException>()
      .having((exception) => exception.type, 'type', type)
      .having(
        (exception) => exception.message,
        'message',
        allOf([for (final culprit in culprits) contains(culprit)]),
      ),
);

void main() {
  late ReferenceInterModuleCommunication communication;
  late RecordingAppLogger logger;
  late RecordingCrashReporter crashReporter;

  setUp(() {
    communication = ReferenceInterModuleCommunication();
    logger = RecordingAppLogger();
    crashReporter = RecordingCrashReporter();
  });

  Future<void> bootstrap(ModularAppContainer container) => container.bootstrap(
    communication: communication,
    contextFor: FakeMicroAppContexts.factory(
      communication: communication,
      logger: logger,
      crashReporter: crashReporter,
    ),
  );

  group('Given the Home, Accounts, and Transfers micro apps', () {
    late List<String> journal;
    late SampleMicroApp home;
    late SampleAccountsMicroApp accounts;
    late SampleTransfersMicroApp transfers;
    late ModularAppContainer container;

    setUp(() async {
      journal = [];
      home = SampleMicroApps.home(journal: journal);
      accounts = SampleAccountsMicroApp(journal: journal);
      transfers = SampleTransfersMicroApp(journal: journal);
      container = ModularAppContainer(microApps: [home, accounts, transfers]);
      await bootstrap(container);
    });

    test('When it bootstraps, '
        'Then the micro apps initialize once each, in order', () {
      // Given: the bootstrapped container.

      // When
      final events = journal;

      // Then
      expect(events, [
        'home.initialize',
        'accounts.initialize',
        'transfers.initialize',
      ]);
      expect(container.isInitialized, isTrue);
    });

    test('When it bootstraps, '
        'Then each micro app gets its own context', () {
      // Given: the bootstrapped container.

      // When
      final contexts = container.contexts;

      // Then
      expect(contexts.keys, ['home', 'accounts', 'transfers']);
      expect(contexts['accounts'], same(accounts.context));
      expect(contexts['transfers'], same(transfers.context));
      expect(
        accounts.context.keyValueStore,
        isNot(same(transfers.context.keyValueStore)),
      );
      expect(
        accounts.context.communication,
        same(transfers.context.communication),
      );
    });

    test('When the routes are read by micro app, '
        'Then each tree is the one its micro app declared', () {
      // Given
      final declared = accounts.routes;

      // When
      final handedOver = container.routesByMicroApp;

      // Then
      expect(handedOver.keys, ['home', 'accounts', 'transfers']);
      final accountsRoutes = handedOver['accounts']!;
      expect(
        accountsRoutes.map((node) => node.toString()),
        declared.map((node) => node.toString()),
      );
      final group = accountsRoutes.whereType<MicroAppRouteGroup>().single;
      expect(group.routes.map((node) => node.toString()), [
        'MicroAppRoute(/accounts/tabs/overview)',
        'MicroAppRoute(/accounts/tabs/history)',
      ]);
      final first = accountsRoutes.first as MicroAppRoute;
      expect(
        first.routes.single.toString(),
        'MicroAppRoute(details/:accountId)',
      );
    });

    test('When all routes are read, '
        'Then they are every micro app\'s top-level nodes, in order', () {
      // Given
      final byMicroApp = container.routesByMicroApp;

      // When
      final routes = container.routes;

      // Then
      expect(routes, [for (final nodes in byMicroApp.values) ...nodes]);
      expect(routes.first.toString(), 'MicroAppRoute(/home)');
      expect(routes.last.toString(), 'MicroAppRoute(/transfers)');
    });

    test('When a gathered list is changed, '
        'Then it refuses, so the declarations stay as declared', () {
      // Given
      final routes = container.routes;

      // When
      void change() => routes.clear();

      // Then
      expect(change, throwsUnsupportedError);
    });

    test('When the localization delegates are read, '
        'Then they follow micro app order, also by micro app', () {
      // Given: every sample micro app declares one delegate.

      // When
      final delegates = container.localizationsDelegates;
      final byMicroApp = container.localizationsDelegatesByMicroApp;

      // Then
      expect(delegates, hasLength(3));
      expect(byMicroApp.keys, ['home', 'accounts', 'transfers']);
      expect(byMicroApp['accounts'], [DefaultMaterialLocalizations.delegate]);
    });

    test('When the stored keys are read, '
        'Then each micro app\'s declared keys are listed', () {
      // Given: Accounts and Transfers declare one key each.

      // When
      final keys = container.storedKeysByMicroApp;

      // Then
      expect(keys, {
        'home': <String>{},
        'accounts': {'accounts.last_balance'},
        'transfers': {'transfers.draft'},
      });
    });

    test('When the endpoints are read, '
        'Then each micro app\'s endpoints are listed and registered', () {
      // Given: the bootstrapped container.

      // When
      final endpoints = container.endpointsByMicroApp.map(
        (id, list) => MapEntry(id, [for (final e in list) e.url]),
      );

      // Then
      expect(endpoints, {
        'home': <String>[],
        'accounts': ['/accounts/v1/balance', '/accounts/v1/balance-card'],
        'transfers': ['/transfers/v1/draft-count'],
      });
      expect(
        communication.isRegistered(
          url: '/accounts/v1/balance-card',
          type: EndpointType.widget,
        ),
        isTrue,
      );
      expect(
        communication.isRegistered(
          url: '/transfers/v1/draft-count',
          type: EndpointType.data,
        ),
        isTrue,
      );
    });

    test('When a micro app initializes, '
        'Then its start-up time is logged at debug level', () {
      // Given: the bootstrapped container.

      // When
      final entries = logger.entries;

      // Then
      expect(entries, hasLength(3));
      expect(entries.map((entry) => entry.level), everyElement(LogLevel.debug));
      expect(entries.map((entry) => entry.context['microAppId']), [
        'home',
        'accounts',
        'transfers',
      ]);
      expect(entries.first.context['durationMs'], isA<int>());
    });

    test('When it is bootstrapped again, '
        'Then it throws alreadyBootstrapped', () {
      // Given: the bootstrapped container.

      // When
      final again = bootstrap(container);

      // Then
      expect(
        again,
        _startupFailure(ModularAppStartupExceptionType.alreadyBootstrapped, [
          'already',
        ]),
      );
    });

    test('When it is disposed, '
        'Then the micro apps dispose in reverse order, once', () async {
      // Given
      journal.clear();

      // When
      final failures = await container.dispose();
      final again = await container.dispose();

      // Then
      expect(failures, isEmpty);
      expect(again, isEmpty);
      expect(journal, [
        'transfers.dispose',
        'accounts.dispose',
        'home.dispose',
      ]);
      expect(container.isInitialized, isFalse);
      expect(container.routes, isNotEmpty);
    });
  });

  group('Given micro apps and the host\'s own declarations', () {
    const hostDelegate = _NamedDelegate('host');
    late MicroAppRoute signIn;
    late MicroAppRoute settings;
    late MicroAppRouteGroup help;
    late ModularAppContainer container;

    setUp(() async {
      signIn = MicroAppRoute(
        path: '/sign-in',
        builder: (context, parameters, body) => const SizedBox(),
        requiresAuthentication: false,
      );
      settings = MicroAppRoute(
        path: '/settings',
        builder: (context, parameters, body) => const SizedBox(),
        routes: [
          MicroAppRoute(
            path: 'privacy',
            builder: (context, parameters, body) => const SizedBox(),
          ),
        ],
      );
      help = MicroAppRouteGroup(
        builder: (context, child) => child,
        routes: [
          MicroAppRoute(
            path: '/help',
            builder: (context, parameters, body) => const SizedBox(),
            requiresAuthentication: false,
          ),
        ],
      );
      container = ModularAppContainer(
        microApps: [SampleAccountsMicroApp(), SampleTransfersMicroApp()],
        host: ModularAppHost(
          routes: [signIn, settings, help],
          localizationsDelegates: const [hostDelegate],
          storedKeys: const {'app.locale'},
          dataEndpoints: const [_AppVersionProvider()],
          widgetEndpoints: const [_AppBannerProvider()],
        ),
      );
      await bootstrap(container);
    });

    test('When all routes are read, '
        'Then the host routes come first, as declared', () {
      // Given
      final byMicroApp = container.routesByMicroApp;

      // When
      final routes = container.routes;

      // Then
      expect(routes, [
        same(signIn),
        same(settings),
        same(help),
        for (final nodes in byMicroApp.values)
          for (final node in nodes) same(node),
      ]);
    });

    test('When the routes are read by micro app, '
        'Then the host routes are not among them', () {
      // Given: the bootstrapped container.

      // When
      final byMicroApp = container.routesByMicroApp;

      // Then
      expect(byMicroApp.keys, ['accounts', 'transfers']);
      expect(
        byMicroApp.values.expand((nodes) => nodes),
        isNot(anyOf(contains(signIn), contains(settings), contains(help))),
      );
    });

    test('When a host route is looked up, '
        'Then it has a sign-in requirement and no micro app', () {
      // Given
      const paths = ['/sign-in', '/settings', '/settings/privacy', '/help'];

      // When
      final requiresAuthentication = [
        for (final path in paths) container.requiresAuthentication(path),
      ];
      final owners = [for (final path in paths) container.microAppIdOf(path)];

      // Then: privacy inherits the requirement of settings.
      expect(requiresAuthentication, [false, true, true, false]);
      expect(owners, everyElement(isNull));
      expect(container.microAppIdOf('/transfers'), 'transfers');
    });

    test('When the localization delegates are read, '
        'Then the host\'s come first and stay out of the by-micro-app map', () {
      // Given: the bootstrapped container.

      // When
      final delegates = container.localizationsDelegates;

      // Then
      expect(delegates.first, same(hostDelegate));
      expect(delegates, [
        hostDelegate,
        for (final list in container.localizationsDelegatesByMicroApp.values)
          ...list,
      ]);
    });

    test('When the stored keys are read, '
        'Then the host\'s are kept apart from the micro apps\'', () {
      // Given: the bootstrapped container.

      // When
      final hostKeys = container.hostStoredKeys;

      // Then
      expect(hostKeys, {'app.locale'});
      expect(container.storedKeysByMicroApp.keys, ['accounts', 'transfers']);
    });

    test('When the endpoints are read, '
        'Then the host\'s are listed and registered', () {
      // Given: the bootstrapped container.

      // When
      final urls = [for (final e in container.hostEndpoints) e.url];

      // Then
      expect(urls, ['/app/v1/version', '/app/v1/banner']);
      expect(
        communication.isRegistered(
          url: '/app/v1/version',
          type: EndpointType.data,
        ),
        isTrue,
      );
      expect(
        communication.isRegistered(
          url: '/app/v1/banner',
          type: EndpointType.widget,
        ),
        isTrue,
      );
      expect(container.endpointsByMicroApp.keys, ['accounts', 'transfers']);
    });
  });

  group('Given micro apps whose declarations collide', () {
    test('When two micro apps share an id, '
        'Then startup stops naming the id before any initialize', () async {
      // Given
      final journal = <String>[];
      final container = ModularAppContainer(
        microApps: [
          SampleAccountsMicroApp(journal: journal),
          SampleAccountsMicroApp(journal: journal),
        ],
      );

      // When
      final bootstrapping = bootstrap(container);

      // Then
      await expectLater(
        bootstrapping,
        _startupFailure(ModularAppStartupExceptionType.duplicateMicroAppId, [
          '"accounts"',
        ]),
      );
      expect(journal, isEmpty);
    });

    test('When two micro apps declare the same stored key, '
        'Then startup stops naming the key and both micro apps', () async {
      // Given
      final container = ModularAppContainer(
        microApps: [
          SampleAccountsMicroApp(extraStoredKeys: {'session_cache'}),
          SampleTransfersMicroApp(extraStoredKeys: {'session_cache'}),
        ],
      );

      // When
      final bootstrapping = bootstrap(container);

      // Then
      await expectLater(
        bootstrapping,
        _startupFailure(ModularAppStartupExceptionType.duplicateStoredKey, [
          'session_cache',
          '"accounts"',
          '"transfers"',
        ]),
      );
    });

    test(
      'When the host and a micro app declare the same stored key, '
      'Then startup stops naming the key, the host, and the micro app',
      () async {
        // Given
        final journal = <String>[];
        final container = ModularAppContainer(
          microApps: [SampleAccountsMicroApp(journal: journal)],
          host: const ModularAppHost(storedKeys: {'accounts.last_balance'}),
        );

        // When
        final bootstrapping = bootstrap(container);

        // Then
        await expectLater(
          bootstrapping,
          _startupFailure(ModularAppStartupExceptionType.duplicateStoredKey, [
            'accounts.last_balance',
            'the host',
            '"accounts"',
          ]),
        );
        expect(journal, isEmpty);
      },
    );

    test('When the host and a micro app declare the same provider URL, '
        'Then DuplicateEndpointException propagates', () async {
      // Given
      final container = ModularAppContainer(
        microApps: [SampleAccountsMicroApp()],
        host: ModularAppHost(
          dataEndpoints: [AccountsBalanceProvider(RecordingApiClient())],
        ),
      );

      // When
      final bootstrapping = bootstrap(container);

      // Then
      await expectLater(
        bootstrapping,
        throwsA(
          isA<DuplicateEndpointException>().having(
            (e) => e.url,
            'url',
            '/accounts/v1/balance',
          ),
        ),
      );
    });

    test('When two micro apps declare the same provider URL, '
        'Then DuplicateEndpointException propagates', () async {
      // Given
      final container = ModularAppContainer(
        microApps: [
          SampleAccountsMicroApp(),
          SampleMicroApp(
            id: 'impostor',
            data: (context) => [AccountsBalanceProvider(context.apiClient)],
          ),
        ],
      );

      // When
      final bootstrapping = bootstrap(container);

      // Then
      await expectLater(
        bootstrapping,
        throwsA(
          isA<DuplicateEndpointException>().having(
            (e) => e.url,
            'url',
            '/accounts/v1/balance',
          ),
        ),
      );
      expect(container.isInitialized, isFalse);
    });
  });

  group('Given a startup exception', () {
    test('When it is printed, Then it shows its type and message', () {
      // Given
      const exception = ModularAppStartupException(
        type: ModularAppStartupExceptionType.duplicateMicroAppId,
        message: 'Duplicate micro app id "accounts".',
      );

      // When
      final text = exception.toString();

      // Then
      expect(
        text,
        'ModularAppStartupException(duplicateMicroAppId): '
        'Duplicate micro app id "accounts".',
      );
    });
  });

  group('Given a micro app whose initialize throws', () {
    test('When the container bootstraps, '
        'Then the failure is reported and rethrown, '
        'and dispose releases only the initialized micro apps', () async {
      // Given
      final journal = <String>[];
      final container = ModularAppContainer(
        microApps: [
          SampleMicroApps.home(journal: journal),
          _FailingMicroApp(id: 'broken', journal: journal),
          SampleTransfersMicroApp(journal: journal),
        ],
      );

      // When
      final bootstrapping = bootstrap(container);

      // Then
      await expectLater(bootstrapping, throwsStateError);
      final error = logger.entries.singleWhere(
        (entry) => entry.level == LogLevel.error,
      );
      expect(error.context, {'microAppId': 'broken'});
      expect(crashReporter.errors.single.$2, 'Micro app failed to initialize');
      journal.clear();
      expect(await container.dispose(), isEmpty);
      expect(journal, ['home.dispose']);
    });
  });

  group('Given a micro app whose teardown throws', () {
    test('When the container is disposed, '
        'Then the failure is reported and the others still dispose', () async {
      // Given
      final journal = <String>[];
      final container = ModularAppContainer(
        microApps: [
          SampleMicroApps.home(journal: journal),
          SampleAccountsMicroApp(journal: journal, failOnDispose: true),
          SampleTransfersMicroApp(journal: journal),
        ],
      );
      await bootstrap(container);
      journal.clear();

      // When
      final failures = await container.dispose();

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
      expect(crashReporter.errors.single.$2, 'Micro app failed to dispose');
    });
  });

  group('Given micro apps that declare their own delegates', () {
    test('When the delegates are read, '
        'Then each micro app\'s list is kept as declared', () async {
      // Given
      const a1 = _NamedDelegate('a1');
      const a2 = _NamedDelegate('a2');
      const b1 = _NamedDelegate('b1');
      final container = ModularAppContainer(
        microApps: [
          _LocalizedMicroApp(id: 'alpha', delegates: const [a1, a2]),
          _LocalizedMicroApp(id: 'beta', delegates: const [b1]),
        ],
      );

      // When
      await bootstrap(container);

      // Then
      expect(container.localizationsDelegatesByMicroApp, {
        'alpha': [a1, a2],
        'beta': [b1],
      });
      expect(container.localizationsDelegates, [a1, a2, b1]);
    });
  });

  group('Given a container that has not bootstrapped', () {
    test('When its declarations are read, '
        'Then each read throws a StateError', () async {
      // Given
      final container = ModularAppContainer(
        microApps: [SampleAccountsMicroApp()],
      );

      // When
      final reads = <Object? Function()>[
        () => container.routes,
        () => container.routesByMicroApp,
        () => container.localizationsDelegates,
        () => container.localizationsDelegatesByMicroApp,
        () => container.contexts,
        () => container.storedKeysByMicroApp,
        () => container.hostStoredKeys,
        () => container.endpointsByMicroApp,
        () => container.hostEndpoints,
        () => container.requiresAuthentication('/accounts'),
        () => container.microAppIdOf('/accounts'),
      ];

      // Then
      for (final read in reads) {
        expect(read, throwsStateError);
      }
      expect(container.isInitialized, isFalse);
      expect(await container.dispose(), isEmpty);
    });

    test('When the list it was given changes, '
        'Then its micro apps stay the same', () {
      // Given
      final microApps = <MicroApp>[SampleAccountsMicroApp()];
      final container = ModularAppContainer(microApps: microApps);

      // When
      microApps.add(SampleTransfersMicroApp());

      // Then
      expect(container.microApps.map((app) => app.id), ['accounts']);
    });
  });

  group('Given a host whose lists are changed after bootstrap', () {
    test('When the gathered declarations are read, '
        'Then they keep what bootstrap read', () async {
      // Given
      final signIn = MicroAppRoute(
        path: '/sign-in',
        builder: (context, parameters, body) => const SizedBox(),
        requiresAuthentication: false,
      );
      final routes = <MicroAppRouteNode>[signIn];
      final delegates = <LocalizationsDelegate<Object?>>[
        const _NamedDelegate('host'),
      ];
      final storedKeys = {'app.locale'};
      final data = <DataEndpointProvider>[const _AppVersionProvider()];
      final container = ModularAppContainer(
        microApps: const [],
        host: ModularAppHost(
          routes: routes,
          localizationsDelegates: delegates,
          storedKeys: storedKeys,
          dataEndpoints: data,
        ),
      );
      await bootstrap(container);

      // When
      routes.clear();
      delegates.clear();
      storedKeys.clear();
      data.clear();

      // Then
      expect(container.routes, [same(signIn)]);
      expect(container.localizationsDelegates, hasLength(1));
      expect(container.hostStoredKeys, {'app.locale'});
      expect(container.hostEndpoints.single.url, '/app/v1/version');
      expect(() => container.hostStoredKeys.clear(), throwsUnsupportedError);
    });
  });
}

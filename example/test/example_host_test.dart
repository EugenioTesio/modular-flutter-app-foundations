// Feature: The example host integrates every module through MicroApp and
// MicroAppContext only (User Story 3; contracts/micro-app.md, "Host
// sequence").
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';
import 'package:foundations_example/cards.dart';
import 'package:foundations_example/home.dart';
import 'package:foundations_example/host/example_host.dart';
import 'package:foundations_example/host/example_navigator.dart';
import 'package:foundations_example/host/example_services.dart';
import 'package:foundations_example/transfers.dart';

/// Records the context it receives and its disposal, and declares the given
/// stored keys and routes.
final class _RecordingMicroApp implements MicroApp {
  _RecordingMicroApp(
    this.id, {
    this.storedKeys = const {},
    this.routes = const [],
    this.disposed,
    this.disposeError,
  });

  @override
  final String id;

  @override
  final Set<String> storedKeys;

  @override
  final List<MicroAppRouteNode> routes;

  /// Receives this micro app's id when it is disposed.
  final List<String>? disposed;

  /// Thrown from [dispose] when set.
  final Object? disposeError;

  MicroAppContext? context;

  @override
  Future<void> initialize(MicroAppContext context) async =>
      this.context = context;

  @override
  List<LocalizationsDelegate<Object?>> get localizationsDelegates => const [];

  @override
  List<DataEndpointProvider> get dataEndpoints => const [];

  @override
  List<WidgetEndpointProvider> get widgetEndpoints => const [];

  @override
  Future<void> dispose() async {
    disposed?.add(id);
    if (disposeError case final error?) throw error;
  }
}

ExampleHost _host(
  List<MicroApp> microApps, {
  SessionState session = DemoSessions.signedIn,
  String initialLocation = '/',
}) => ExampleHost(
  session: ExampleSessionContext(session),
  microApps: microApps,
  initialLocation: initialLocation,
);

/// Shows the host's go_router, as the example app does.
Future<void> _pumpRouter(WidgetTester tester, ExampleHost host) =>
    tester.pumpWidget(
      MaterialApp.router(
        theme: DsTheme.light(),
        routerConfig: host.navigator.router,
      ),
    );

MicroAppRoute _route(
  String path, {
  bool requiresAuthentication = true,
  List<MicroAppRouteNode> routes = const [],
}) => MicroAppRoute(
  path: path,
  requiresAuthentication: requiresAuthentication,
  builder: (context, parameters, body) => Text(path),
  routes: routes,
);

Matcher _startupError(List<String> parts) => throwsA(
  isA<StateError>().having(
    (e) => e.message,
    'message',
    allOf([for (final part in parts) contains(part)]),
  ),
);

void main() {
  group('Given the example modules', () {
    test('When the host starts them, '
        'Then each declared endpoint is registered by type', () async {
      // Given
      final host = _host([
        HomeMicroApp(),
        TransfersMicroApp(prepareScenario: (_) {}),
        CardsMicroApp(),
      ]);

      // When
      await host.start();

      // Then
      final communication = host.communication;
      expect(
        communication.isRegistered(
          url: '/cards/v1/details',
          type: EndpointType.data,
        ),
        isTrue,
      );
      expect(
        communication.isRegistered(
          url: '/cards/v1/home-banner',
          type: EndpointType.widget,
        ),
        isTrue,
      );
      expect(
        communication.isRegistered(
          url: '/transfers/v1/home-shortcut',
          type: EndpointType.widget,
        ),
        isTrue,
      );
    });

    testWidgets('When Transfers\' path is pushed, '
        'Then the route Transfers declared opens', (tester) async {
      // Given
      final host = _host([
        HomeMicroApp(),
        TransfersMicroApp(prepareScenario: (_) {}),
        CardsMicroApp(),
      ], initialLocation: '/home');
      await host.start();
      final navigator = host.navigator;
      await _pumpRouter(tester, host);

      // When
      final pushed = navigator.push(TransfersMicroApp.path);
      await tester.pumpAndSettle();
      final unknown = await navigator.push('/nowhere');

      // Then
      expect(find.byType(TransfersScreen), findsOneWidget);
      expect(
        unknown,
        const Err<NavigationResult, NavigationException>(
          RouteNotFoundException('/nowhere'),
        ),
      );
      navigator.pop();
      await tester.pumpAndSettle();
      expect(
        await pushed,
        const Ok<NavigationResult, NavigationException>(RouteCancelled()),
      );
    });
  });

  group('Given two micro apps', () {
    test('When the host starts them, Then each gets its own context with '
        'shared services and its own stores', () async {
      // Given
      final first = _RecordingMicroApp('first', storedKeys: {'first.key'});
      final second = _RecordingMicroApp('second', storedKeys: {'second.key'});
      final host = _host([first, second]);

      // When
      await host.start();

      // Then
      final a = first.context!;
      final b = second.context!;
      expect(a.communication, same(b.communication));
      expect(a.session, same(b.session));
      expect(a.navigator, same(b.navigator));
      expect(
        await a.keyValueStore.write('first.key', 'v'),
        const Ok<void, StorageException>(null),
      );
      expect(
        await b.keyValueStore.write('first.key', 'v'),
        const Err<void, StorageException>(
          StorageException(
            type: StorageExceptionType.undeclaredKey,
            key: 'first.key',
          ),
        ),
      );
    });

    test('When they share an id, Then startup stops naming it', () async {
      // Given
      final host = _host([
        _RecordingMicroApp('same'),
        _RecordingMicroApp('same'),
      ]);

      // When
      final starting = host.start();

      // Then
      await expectLater(
        starting,
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('"same"'),
          ),
        ),
      );
    });
  });

  group('Given micro apps whose route paths break a rule', () {
    test('When one declares the same full path twice, '
        'Then startup stops naming the path and the micro app', () async {
      // Given
      final host = _host([
        _RecordingMicroApp(
          'first',
          routes: [_route('/first/:id'), _route('/first/:key')],
        ),
      ]);

      // When
      final starting = host.start();

      // Then
      await expectLater(
        starting,
        _startupError(['Duplicate route path', '/first/:key', '"first"']),
      );
    });

    test('When a top-level path lacks the micro app id prefix, '
        'Then startup stops naming the path and the micro app', () async {
      // Given
      final host = _host([
        _RecordingMicroApp('first', routes: [_route('/other')]),
      ]);

      // When
      final starting = host.start();

      // Then
      await expectLater(starting, _startupError(['"/other"', '"first"']));
    });
  });

  group('Given a signed-out user', () {
    Future<ExampleNavigator> pumpHost(
      WidgetTester tester, {
      String initialLocation = '/public',
    }) async {
      final host = _host(
        [
          _RecordingMicroApp(
            'secure',
            routes: [
              _route('/secure', routes: [_route('details')]),
            ],
          ),
          _RecordingMicroApp(
            'public',
            routes: [
              _route(
                '/public',
                requiresAuthentication: false,
                routes: [_route('about', requiresAuthentication: false)],
              ),
            ],
          ),
        ],
        session: DemoSessions.signedOut,
        initialLocation: initialLocation,
      );
      await host.start();
      await _pumpRouter(tester, host);
      return host.navigator;
    }

    testWidgets('When a route that inherits the sign-in requirement is '
        'pushed, Then the sign-in screen shows and closing it cancels', (
      tester,
    ) async {
      // Given
      final navigator = await pumpHost(tester);

      // When
      final pushed = navigator.push('/secure/details');
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(ExampleSignInRequiredScreen), findsOneWidget);
      expect(find.text('details'), findsNothing);

      // When
      navigator.pop();
      await tester.pumpAndSettle();

      // Then
      expect(
        await pushed,
        const Ok<NavigationResult, NavigationException>(RouteCancelled()),
      );
    });

    testWidgets('When a route that does not require sign-in is pushed, '
        'Then it opens', (tester) async {
      // Given
      final navigator = await pumpHost(tester);

      // When
      unawaited(navigator.push('/public/about'));
      await tester.pumpAndSettle();

      // Then
      expect(find.text('about'), findsOneWidget);
      expect(find.byType(ExampleSignInRequiredScreen), findsNothing);
    });

    testWidgets('When the app opens from a deep link to a route that '
        'requires sign-in, Then the redirect shows the sign-in screen', (
      tester,
    ) async {
      // When
      await pumpHost(tester, initialLocation: '/secure');
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(ExampleSignInRequiredScreen), findsOneWidget);
      expect(find.text('/secure'), findsNothing);
    });

    testWidgets('When the app opens from a deep link that matches no route, '
        'Then the not-found screen shows', (tester) async {
      // When
      await pumpHost(tester, initialLocation: '/nowhere');
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(ExampleRouteNotFoundScreen), findsOneWidget);
      expect(find.text('Nothing is available at /nowhere.'), findsOneWidget);
    });
  });

  group(
    'Given three started micro apps, the middle one failing to dispose',
    () {
      test('When the host is disposed, Then it disposes all three in reverse '
          'order and reports the failure', () async {
        // Given
        final disposed = <String>[];
        final failure = StateError('still listening');
        final host = _host([
          _RecordingMicroApp('a', disposed: disposed),
          _RecordingMicroApp('b', disposed: disposed, disposeError: failure),
          _RecordingMicroApp('c', disposed: disposed),
        ]);
        await host.start();

        // When
        final failures = await host.dispose();

        // Then
        expect(disposed, ['c', 'b', 'a']);
        expect(failures, [('b', failure)]);
      });
    },
  );
}

// Feature: The example host integrates every module through MicroApp and
// MicroAppContext only (User Story 3; contracts/micro-app.md, "Host
// sequence").
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';
import 'package:foundations_example/cards.dart';
import 'package:foundations_example/home.dart';
import 'package:foundations_example/host/example_host.dart';
import 'package:foundations_example/host/example_services.dart';
import 'package:foundations_example/transfers.dart';

/// Records the context it receives, and declares one stored key.
final class _RecordingMicroApp implements MicroApp {
  _RecordingMicroApp(this.id, {this.storedKeys = const {}});

  @override
  final String id;

  @override
  final Set<String> storedKeys;

  MicroAppContext? context;

  @override
  Future<void> initialize(MicroAppContext context) async =>
      this.context = context;

  @override
  List<MicroAppRouteNode> get routes => const [];

  @override
  List<LocalizationsDelegate<Object?>> get localizationsDelegates => const [];

  @override
  List<DataEndpointProvider> get dataEndpoints => const [];

  @override
  List<WidgetEndpointProvider> get widgetEndpoints => const [];

  @override
  Future<void> dispose() async {}
}

ExampleHost _host(List<MicroApp> microApps) => ExampleHost(
  session: ExampleSessionContext(DemoSessions.signedIn),
  microApps: microApps,
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
      ]);
      await host.start();
      final navigator = host.navigator;
      await tester.pumpWidget(
        MaterialApp(
          theme: DsTheme.light(),
          navigatorKey: navigator.navigatorKey,
          navigatorObservers: [navigator.observer],
          onGenerateRoute: navigator.onGenerateRoute,
          onGenerateInitialRoutes: (_) => [
            navigator.onGenerateRoute(const RouteSettings(name: '/home'))!,
          ],
        ),
      );

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
}

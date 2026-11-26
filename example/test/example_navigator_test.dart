// Feature: The example navigator keeps no stack of its own. It reads
// go_router's match list, and every screen that closes completes its opener
// (contracts/routing.md, "Navigation outcomes").
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';
import 'package:foundations_example/host/example_navigator.dart';
import 'package:foundations_example/host/example_services.dart';
import 'package:foundations_example/transfers.dart';

typedef _Outcome = Result<NavigationResult, NavigationException>;

const _cancelled = Ok<NavigationResult, NavigationException>(RouteCancelled());

MicroAppRoute _route(
  String path, {
  List<MicroAppRouteNode> routes = const [],
}) => MicroAppRoute(
  path: path,
  builder: (context, parameters, body) => Text('screen $path'),
  routes: routes,
);

/// Shows a navigator over `/app` (with `one` and `two` below it) and a group
/// holding `/app/tabs/a` and `/app/tabs/b`, starting at [initialLocation].
Future<ExampleNavigator> _pumpNavigator(
  WidgetTester tester, {
  String initialLocation = '/app',
}) async {
  final navigator =
      ExampleNavigator(session: ExampleSessionContext(DemoSessions.signedIn))
        ..install(
          routes: [
            _route('/app', routes: [_route('one'), _route('two')]),
            MicroAppRouteGroup(
              builder: (context, child) => child,
              routes: [_route('/app/tabs/a'), _route('/app/tabs/b')],
            ),
          ],
          requiresAuthentication: (fullPath) => false,
          initialLocation: initialLocation,
        );
  await tester.pumpWidget(MaterialApp.router(routerConfig: navigator.router));
  await tester.pumpAndSettle();
  return navigator;
}

/// Pushes [path] and lets the new screen settle.
Future<Future<_Outcome>> _push(
  WidgetTester tester,
  ExampleNavigator navigator,
  String path,
) async {
  final outcome = navigator.push(path);
  await tester.pumpAndSettle();
  return outcome;
}

void main() {
  group('Given /app with /app/one and /app/two pushed on it', () {
    late ExampleNavigator navigator;
    late Future<_Outcome> openedOne;
    late Future<_Outcome> openedTwo;

    Future<void> pumpStack(WidgetTester tester) async {
      navigator = await _pumpNavigator(tester);
      openedOne = await _push(tester, navigator, '/app/one');
      openedTwo = await _push(tester, navigator, '/app/two');
    }

    testWidgets('When the stack is read, Then it lists go_router\'s screens '
        'bottom first', (tester) async {
      // Given
      await pumpStack(tester);

      // When
      final locations = navigator.locations;

      // Then
      expect(locations, ['/app', '/app/one', '/app/two']);
      expect(find.text('screen two'), findsOneWidget);
    });

    testWidgets('When popUntil goes back to /app, Then both screens close '
        'and each opener completes with RouteCancelled', (tester) async {
      // Given
      await pumpStack(tester);

      // When
      final result = navigator.popUntil('/app');
      await tester.pumpAndSettle();

      // Then
      expect(result, const Ok<void, NavigationException>(null));
      expect(navigator.locations, ['/app']);
      expect(find.text('screen /app'), findsOneWidget);
      expect(await openedOne, _cancelled);
      expect(await openedTwo, _cancelled);
    });

    testWidgets('When popUntil names a path with a query string, Then the '
        'query is ignored', (tester) async {
      // Given
      await pumpStack(tester);

      // When
      final result = navigator.popUntil('/app/one?tab=history');
      await tester.pumpAndSettle();

      // Then
      expect(result, const Ok<void, NavigationException>(null));
      expect(navigator.locations, ['/app', '/app/one']);
      expect(await openedTwo, _cancelled);
    });

    testWidgets('When popUntil names the screen on top, Then nothing closes', (
      tester,
    ) async {
      // Given
      await pumpStack(tester);

      // When
      final result = navigator.popUntil('/app/two');
      await tester.pumpAndSettle();

      // Then
      expect(result, const Ok<void, NavigationException>(null));
      expect(navigator.locations, ['/app', '/app/one', '/app/two']);
    });

    testWidgets('When popUntil names a path that is not on the stack, Then it '
        'returns RouteNotFoundException and closes nothing', (tester) async {
      // Given
      await pumpStack(tester);

      // When
      final missing = navigator.popUntil('/app/tabs/a');
      final malformed = navigator.popUntil('/app/%');
      await tester.pumpAndSettle();

      // Then
      expect(
        missing,
        const Err<void, NavigationException>(
          RouteNotFoundException('/app/tabs/a'),
        ),
      );
      expect(
        malformed,
        const Err<void, NavigationException>(RouteNotFoundException('/app/%')),
      );
      expect(navigator.locations, ['/app', '/app/one', '/app/two']);
    });

    testWidgets('When go replaces the stack, Then each pushed screen\'s '
        'opener completes with RouteCancelled', (tester) async {
      // Given
      await pumpStack(tester);

      // When
      final result = navigator.go('/app/tabs/a');
      await tester.pumpAndSettle();

      // Then
      expect(result, const Ok<void, NavigationException>(null));
      expect(navigator.locations, ['/app/tabs/a']);
      expect(await openedOne, _cancelled);
      expect(await openedTwo, _cancelled);
    });

    testWidgets('When the top screen is replaced and the new one closes with '
        'a result, Then the replaced screen\'s opener is cancelled and the '
        'new one\'s opener gets the result', (tester) async {
      // Given
      await pumpStack(tester);

      // When
      final replaced = navigator.replace('/app/tabs/b');
      await tester.pumpAndSettle();

      // Then
      expect(navigator.locations, ['/app', '/app/one', '/app/tabs/b']);
      expect(await openedTwo, _cancelled);

      // When
      navigator.pop(result: {'saved': true});
      await tester.pumpAndSettle();

      // Then
      expect(
        await replaced,
        const Ok<NavigationResult, NavigationException>(
          RouteCompleted({'saved': true}),
        ),
      );
      expect(navigator.locations, ['/app', '/app/one']);
    });
  });

  group('Given the same path pushed twice', () {
    testWidgets('When popUntil names it, Then it stops at the upper one', (
      tester,
    ) async {
      // Given
      final navigator = await _pumpNavigator(tester);
      final lower = await _push(tester, navigator, '/app/one');
      final upper = await _push(tester, navigator, '/app/one');
      final top = await _push(tester, navigator, '/app/two');

      // When
      navigator.popUntil('/app/one');
      await tester.pumpAndSettle();

      // Then
      expect(navigator.locations, ['/app', '/app/one', '/app/one']);
      expect(await top, _cancelled);
      var settled = false;
      unawaited(Future.wait([lower, upper]).then((_) => settled = true));
      await tester.pump();
      expect(settled, isFalse);
    });
  });

  group('Given screens in a group pushed over /app', () {
    testWidgets('When popUntil goes back to /app, Then it leaves the group and '
        'cancels both openers', (tester) async {
      // Given
      final navigator = await _pumpNavigator(tester);
      final openedA = await _push(tester, navigator, '/app/tabs/a');
      final openedB = await _push(tester, navigator, '/app/tabs/b');
      expect(navigator.locations, ['/app', '/app/tabs/a', '/app/tabs/b']);

      // When
      navigator.popUntil('/app');
      await tester.pumpAndSettle();

      // Then
      expect(navigator.locations, ['/app']);
      expect(await openedA, _cancelled);
      expect(await openedB, _cancelled);
    });
  });

  group('Given a deep link to a nested route', () {
    testWidgets('When popUntil names its parent, Then the parent\'s screen '
        'stays', (tester) async {
      // Given
      final navigator = await _pumpNavigator(
        tester,
        initialLocation: '/app/two',
      );
      expect(navigator.locations, ['/app', '/app/two']);

      // When
      navigator.popUntil('/app');
      await tester.pumpAndSettle();

      // Then
      expect(navigator.locations, ['/app']);
      expect(find.text('screen /app'), findsOneWidget);
    });
  });

  group('Given only the first screen', () {
    testWidgets('When it is replaced, Then the call completes at once with '
        'RouteCancelled', (tester) async {
      // Given
      final navigator = await _pumpNavigator(tester);

      // When
      final replaced = await navigator.replace('/app/one');
      await tester.pumpAndSettle();

      // Then
      expect(replaced, _cancelled);
      expect(navigator.locations, ['/app', '/app/one']);
      expect(find.text('screen one'), findsOneWidget);
    });

    testWidgets('When pop is called, Then nothing happens', (tester) async {
      // Given
      final navigator = await _pumpNavigator(tester);

      // When
      navigator.pop();
      await tester.pumpAndSettle();

      // Then
      expect(navigator.locations, ['/app']);
    });

    testWidgets('When a malformed path is pushed, Then it returns '
        'RouteNotFoundException', (tester) async {
      // Given
      final navigator = await _pumpNavigator(tester);

      // When
      final pushed = await navigator.push('/app/%');

      // Then
      expect(
        pushed,
        const Err<NavigationResult, NavigationException>(
          RouteNotFoundException('/app/%'),
        ),
      );
    });
  });
}

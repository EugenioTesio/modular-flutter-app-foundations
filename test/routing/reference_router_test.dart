// Feature: The router-neutral route contract builds a real router
// (quickstart.md V10, SC-015; contracts/routing.md, "Navigation outcomes").
// A reference adapter in test/support/ maps the sample micro apps' route
// trees onto go_router, a development-only dependency.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';
import 'package:switchable_state_bloc/switchable_state_bloc.dart';

import '../support/fakes.dart';
import '../support/reference_host.dart';
import '../support/sample_micro_apps.dart';

const _signedIn = Authenticated(UserIdentity(userId: 'user-1'));

/// Starts the host on the sample micro apps and pumps the app at
/// [initialLocation].
Future<ReferenceHost> _pumpApp(
  WidgetTester tester, {
  String initialLocation = '/home',
  SessionState session = _signedIn,
  List<String>? journal,
}) async {
  final host = ReferenceHost(
    microApps: [
      SampleMicroApps.home(),
      SampleMicroApps.auth(),
      SampleAccountsMicroApp(journal: journal),
      SampleTransfersMicroApp(),
    ],
    services: ReferenceHostServices.fakes(session: FakeSessionContext(session)),
    initialLocation: initialLocation,
  );
  await host.start();
  addTearDown(host.dispose);
  await tester.pumpWidget(
    StateScope(
      adapter: const CubitStateAdapter(),
      child: MaterialApp.router(
        routerConfig: host.router!.router,
        localizationsDelegates: host.localizationsDelegates,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return host;
}

void main() {
  group('Given the Accounts details route at /accounts/details/:accountId', () {
    testWidgets('When the app opens from the deep link '
        '/accounts/details/42?tab=movements, '
        'Then the screen gets the merged parameters and an empty body', (
      tester,
    ) async {
      // Given
      const deepLink = '/accounts/details/42?tab=movements';

      // When
      await _pumpApp(tester, initialLocation: deepLink);

      // Then
      expect(find.text('Account details'), findsOneWidget);
      expect(
        find.text('parameters: {accountId: 42, tab: movements}'),
        findsOneWidget,
      );
      expect(find.text('body: {}'), findsOneWidget);
    });

    testWidgets('When the same location is pushed with a body, '
        'Then the same screen also receives the body', (tester) async {
      // Given
      final host = await _pumpApp(tester);

      // When
      final opened = host.navigator.push(
        '/accounts/details/42?tab=movements',
        body: {'source': 'transfers'},
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.text('Account details'), findsOneWidget);
      expect(
        find.text('parameters: {accountId: 42, tab: movements}'),
        findsOneWidget,
      );
      expect(find.text('body: {source: transfers}'), findsOneWidget);
      host.navigator.pop();
      await tester.pumpAndSettle();
      expect(
        await opened,
        const Ok<NavigationResult, NavigationException>(RouteCancelled()),
      );
    });
  });

  group('Given locations that match nothing', () {
    testWidgets('When /nope/screen is pushed, '
        'Then it returns Err(RouteNotFoundException) and nothing opens', (
      tester,
    ) async {
      // Given
      final host = await _pumpApp(tester);

      // When
      final result = await host.navigator.push('/nope/screen');
      await tester.pumpAndSettle();

      // Then
      expect(
        result,
        const Err<NavigationResult, NavigationException>(
          RouteNotFoundException('/nope/screen'),
        ),
      );
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('When go or replace targets an unknown location, '
        'Then each returns Err(RouteNotFoundException)', (tester) async {
      // Given
      final host = await _pumpApp(tester);

      // When
      final went = host.navigator.go('/nope');
      final replaced = await host.navigator.replace('/nope');

      // Then
      expect(
        went,
        const Err<void, NavigationException>(RouteNotFoundException('/nope')),
      );
      expect(
        replaced,
        const Err<NavigationResult, NavigationException>(
          RouteNotFoundException('/nope'),
        ),
      );
    });

    testWidgets('When popUntil targets a path not in the stack, '
        'Then it returns Err(RouteNotFoundException) and closes nothing', (
      tester,
    ) async {
      // Given
      final host = await _pumpApp(tester);
      host.navigator.push('/accounts').ignore();
      await tester.pumpAndSettle();

      // When
      final result = host.navigator.popUntil('/not/in/stack');
      await tester.pumpAndSettle();

      // Then
      expect(
        result,
        const Err<void, NavigationException>(
          RouteNotFoundException('/not/in/stack'),
        ),
      );
      expect(host.router!.stack, ['/home', '/accounts']);
      expect(find.text('Accounts'), findsOneWidget);
    });

    testWidgets('When a deep link matches no route, '
        "Then the host's not-found screen is shown", (tester) async {
      // Given
      const deepLink = '/nope/screen';

      // When
      await _pumpApp(tester, initialLocation: deepLink);

      // Then
      expect(find.text('No screen at /nope/screen'), findsOneWidget);
    });
  });

  group('Given the Accounts picker, which returns a choice', () {
    testWidgets('When it is pushed and closed with a result, '
        'Then push completes with Ok(RouteCompleted(result))', (tester) async {
      // Given
      final host = await _pumpApp(tester);
      final opened = host.navigator.push('/accounts/picker');
      await tester.pumpAndSettle();

      // When
      await tester.tap(find.text('Pick a1'));
      await tester.pumpAndSettle();

      // Then
      expect(
        await opened,
        const Ok<NavigationResult, NavigationException>(
          RouteCompleted({'accountId': 'a1'}),
        ),
      );
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('When it is pushed and closed without a result, '
        'Then push completes with Ok(RouteCancelled())', (tester) async {
      // Given
      final host = await _pumpApp(tester);
      final opened = host.navigator.push('/accounts/picker');
      await tester.pumpAndSettle();

      // When
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Then
      expect(
        await opened,
        const Ok<NavigationResult, NavigationException>(RouteCancelled()),
      );
    });

    testWidgets('When it replaces the current screen and returns a result, '
        'Then replace completes with Ok(RouteCompleted(result))', (
      tester,
    ) async {
      // Given
      final host = await _pumpApp(tester);
      host.navigator.push('/accounts').ignore();
      await tester.pumpAndSettle();

      // When
      final replaced = host.navigator.replace('/accounts/picker');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pick a1'));
      await tester.pumpAndSettle();

      // Then
      expect(
        await replaced,
        const Ok<NavigationResult, NavigationException>(
          RouteCompleted({'accountId': 'a1'}),
        ),
      );
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('When it replaces the current screen and closes without a '
        'result, Then replace completes with Ok(RouteCancelled())', (
      tester,
    ) async {
      // Given
      final host = await _pumpApp(tester);
      host.navigator.push('/accounts').ignore();
      await tester.pumpAndSettle();

      // When
      final replaced = host.navigator.replace('/accounts/picker');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Then
      expect(
        await replaced,
        const Ok<NavigationResult, NavigationException>(RouteCancelled()),
      );
    });
  });

  group('Given screens pushed on top of Home', () {
    testWidgets('When go targets a known location, '
        'Then it returns Ok and replaces the whole stack', (tester) async {
      // Given
      final host = await _pumpApp(tester);
      host.navigator.push('/accounts').ignore();
      await tester.pumpAndSettle();

      // When
      final result = host.navigator.go('/transfers');
      await tester.pumpAndSettle();

      // Then
      expect(result, const Ok<void, NavigationException>(null));
      expect(find.text('Transfers'), findsOneWidget);
      expect(host.router!.currentLocation, '/transfers');
      expect(host.router!.stack, ['/transfers']);
    });

    testWidgets('When popUntil(/home) runs after two pushes, '
        'Then both screens close and each opener gets RouteCancelled', (
      tester,
    ) async {
      // Given
      final host = await _pumpApp(tester);
      final first = host.navigator.push('/accounts');
      await tester.pumpAndSettle();
      final second = host.navigator.push('/transfers');
      await tester.pumpAndSettle();

      // When
      final result = host.navigator.popUntil('/home');
      await tester.pumpAndSettle();

      // Then
      expect(result, const Ok<void, NavigationException>(null));
      expect(find.text('Home'), findsOneWidget);
      expect(host.router!.stack, ['/home']);
      const cancelled = Ok<NavigationResult, NavigationException>(
        RouteCancelled(),
      );
      expect(await first, cancelled);
      expect(await second, cancelled);
    });

    testWidgets('When go replaces the stack, '
        'Then each pushed screen\'s opener gets RouteCancelled', (
      tester,
    ) async {
      // Given
      final host = await _pumpApp(tester);
      final first = host.navigator.push('/accounts');
      await tester.pumpAndSettle();
      final second = host.navigator.push('/transfers');
      await tester.pumpAndSettle();

      // When
      host.navigator.go('/home');
      await tester.pumpAndSettle();

      // Then
      expect(host.router!.stack, ['/home']);
      const cancelled = Ok<NavigationResult, NavigationException>(
        RouteCancelled(),
      );
      expect(await first, cancelled);
      expect(await second, cancelled);
    });

    testWidgets('When the top screen is replaced, '
        'Then the replaced screen\'s opener gets RouteCancelled', (
      tester,
    ) async {
      // Given
      final host = await _pumpApp(tester);
      final opened = host.navigator.push('/accounts');
      await tester.pumpAndSettle();

      // When
      host.navigator.replace('/transfers').ignore();
      await tester.pumpAndSettle();

      // Then
      expect(host.router!.stack, ['/home', '/transfers']);
      expect(
        await opened,
        const Ok<NavigationResult, NavigationException>(RouteCancelled()),
      );
    });

    testWidgets('When popUntil(/home) runs from inside the tab group, '
        'Then it leaves the group and each opener gets RouteCancelled', (
      tester,
    ) async {
      // Given
      final host = await _pumpApp(tester);
      final overview = host.navigator.push('/accounts/tabs/overview');
      await tester.pumpAndSettle();
      final history = host.navigator.push('/accounts/tabs/history');
      await tester.pumpAndSettle();
      expect(host.router!.stack, [
        '/home',
        '/accounts/tabs/overview',
        '/accounts/tabs/history',
      ]);

      // When
      final result = host.navigator.popUntil('/home');
      await tester.pumpAndSettle();

      // Then
      expect(result, const Ok<void, NavigationException>(null));
      expect(find.text('Home'), findsOneWidget);
      expect(host.router!.stack, ['/home']);
      const cancelled = Ok<NavigationResult, NavigationException>(
        RouteCancelled(),
      );
      expect(await overview, cancelled);
      expect(await history, cancelled);
    });
  });

  group('Given Home as the only screen', () {
    testWidgets('When it is replaced, '
        'Then replace completes at once with RouteCancelled', (tester) async {
      // Given
      final host = await _pumpApp(tester);

      // When
      final replaced = await host.navigator.replace('/transfers');
      await tester.pumpAndSettle();

      // Then
      expect(
        replaced,
        const Ok<NavigationResult, NavigationException>(RouteCancelled()),
      );
      expect(host.router!.stack, ['/transfers']);
      expect(find.text('Transfers'), findsOneWidget);
    });
  });

  group('Given a signed-out user', () {
    testWidgets('When a route that requires sign-in through its parent is '
        'opened, Then the host redirects to sign-in', (tester) async {
      // Given: details opts out, but /accounts requires sign-in.
      final host = await _pumpApp(
        tester,
        initialLocation: '/auth/help',
        session: const Unauthenticated(),
      );

      // When
      host.navigator.go('/accounts/details/42');
      await tester.pumpAndSettle();

      // Then
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Account details'), findsNothing);
    });

    testWidgets('When a deep link needs sign-in, '
        'Then the app opens on sign-in', (tester) async {
      // Given
      const deepLink = '/home';

      // When
      await _pumpApp(
        tester,
        initialLocation: deepLink,
        session: const Unauthenticated(),
      );

      // Then
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('When a route with requiresAuthentication: false is opened, '
        'Then it opens', (tester) async {
      // Given
      final host = await _pumpApp(
        tester,
        initialLocation: '/auth/sign-in',
        session: const Unauthenticated(),
      );

      // When
      host.navigator.go('/auth/help');
      await tester.pumpAndSettle();

      // Then
      expect(find.text('Help'), findsOneWidget);
    });

    testWidgets('When a guarded route is pushed and sign-in is abandoned, '
        'Then push completes with Ok(RouteCancelled())', (tester) async {
      // Given
      final host = await _pumpApp(
        tester,
        initialLocation: '/auth/help',
        session: const Unauthenticated(),
      );
      final opened = host.navigator.push('/home');
      await tester.pumpAndSettle();
      expect(find.text('Sign in'), findsOneWidget);

      // When
      host.navigator.pop();
      await tester.pumpAndSettle();

      // Then
      expect(
        await opened,
        const Ok<NavigationResult, NavigationException>(RouteCancelled()),
      );
      expect(find.text('Help'), findsOneWidget);
    });
  });

  group('Given routes with different presentations', () {
    testWidgets('When the fullscreenDialog statement route is pushed, '
        'Then it is presented as a full-screen dialog', (tester) async {
      // Given
      final host = await _pumpApp(tester);

      // When
      host.navigator.push('/accounts/statement').ignore();
      await tester.pumpAndSettle();

      // Then
      expect(find.text('Statement'), findsOneWidget);
      expect(find.text('fullscreenDialog: true'), findsOneWidget);
    });

    testWidgets('When a page route is pushed, '
        'Then it is presented as a regular page', (tester) async {
      // Given
      final host = await _pumpApp(tester);

      // When
      host.navigator.push('/accounts').ignore();
      await tester.pumpAndSettle();

      // Then
      expect(find.text('Accounts'), findsOneWidget);
      expect(find.text('fullscreenDialog: false'), findsOneWidget);
    });
  });

  group('Given the Accounts tab group with a StateScope.group', () {
    testWidgets('When the user moves between tabs, '
        "Then the layout and the group's state are kept", (tester) async {
      // Given
      final journal = <String>[];
      final host = await _pumpApp(
        tester,
        initialLocation: '/accounts/tabs/overview',
        journal: journal,
      );
      await tester.tap(find.text('Visit'));
      await tester.pumpAndSettle();
      expect(find.text('visits: 1'), findsOneWidget);

      // When
      host.navigator.go('/accounts/tabs/history');
      await tester.pumpAndSettle();

      // Then
      expect(find.text('Tab history'), findsOneWidget);
      expect(find.text('visits: 1'), findsOneWidget);
      expect(
        journal.where((event) => event == 'accounts.tabs.layout.init'),
        hasLength(1),
      );
    });

    testWidgets('When the user leaves the group and comes back, '
        "Then the group's state starts over", (tester) async {
      // Given
      final host = await _pumpApp(
        tester,
        initialLocation: '/accounts/tabs/overview',
      );
      await tester.tap(find.text('Visit'));
      await tester.pumpAndSettle();

      // When
      host.navigator.go('/home');
      await tester.pumpAndSettle();
      host.navigator.go('/accounts/tabs/overview');
      await tester.pumpAndSettle();

      // Then
      expect(find.text('visits: 0'), findsOneWidget);
    });
  });
}

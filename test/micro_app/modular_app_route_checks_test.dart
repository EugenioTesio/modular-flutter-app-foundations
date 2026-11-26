// Feature: Route trees are checked at startup, and handed over unchanged
// (contracts/routing.md, "Path rules" and "Startup checks"; data-model.md
// MicroAppRoute.path, MicroAppRoute.requiresAuthentication,
// MicroAppRoute.routes, and MicroAppRouteGroup.routes).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';

import '../support/fakes.dart';
import '../support/reference_inter_module_communication.dart';
import '../support/sample_micro_apps.dart';

Widget _screen(
  BuildContext context,
  Map<String, String> parameters,
  Map<String, Object> body,
) => const SizedBox();

MicroAppRoute _route(
  String path, {
  bool requiresAuthentication = true,
  List<MicroAppRouteNode> routes = const [],
}) => MicroAppRoute(
  path: path,
  builder: _screen,
  requiresAuthentication: requiresAuthentication,
  routes: routes,
);

/// Bootstraps a container whose micro apps declare [routesByMicroApp] and
/// whose host declares [hostRoutes].
Future<ModularAppContainer> _bootstrap(
  Map<String, List<MicroAppRouteNode>> routesByMicroApp, {
  List<MicroAppRouteNode> hostRoutes = const [],
}) async {
  final container = ModularAppContainer(
    microApps: [
      for (final MapEntry(key: id, value: routes) in routesByMicroApp.entries)
        SampleMicroApp(id: id, routes: (_) => routes),
    ],
    host: ModularAppHost(routes: hostRoutes),
  );
  final communication = ReferenceInterModuleCommunication();
  await container.bootstrap(
    communication: communication,
    contextFor: FakeMicroAppContexts.factory(communication: communication),
  );
  return container;
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
  group('Given a route tree with nested routes and a group', () {
    final tree = <MicroAppRouteNode>[
      _route(
        '/accounts',
        routes: [
          _route(
            'details/:accountId',
            requiresAuthentication: false,
            routes: [_route('movements')],
          ),
        ],
      ),
      _route('/accounts/welcome', requiresAuthentication: false),
      MicroAppRouteGroup(
        builder: (context, child) => child,
        routes: [_route('/accounts/tabs/overview')],
      ),
    ];

    test('When it is bootstrapped, '
        'Then the tree is handed over unchanged', () async {
      // Given
      final routesByMicroApp = {'accounts': tree};

      // When
      final container = await _bootstrap(routesByMicroApp);

      // Then
      final handedOver = container.routesByMicroApp['accounts']!;
      expect(handedOver, hasLength(tree.length));
      for (final (index, node) in tree.indexed) {
        expect(handedOver[index], same(node));
      }
      expect(container.routes, handedOver);
    });

    test('When a full path is looked up, '
        'Then the sign-in requirement is inherited from ancestors', () async {
      // Given
      final container = await _bootstrap({'accounts': tree});

      // When
      final requiresAuthentication = {
        for (final path in const [
          '/accounts',
          '/accounts/details/:accountId',
          '/accounts/details/:accountId/movements',
          '/accounts/welcome',
          '/accounts/tabs/overview',
          '/sign-in',
        ])
          path: container.requiresAuthentication(path),
      };

      // Then
      expect(requiresAuthentication, {
        '/accounts': true,
        // Opts out, but '/accounts' requires sign-in.
        '/accounts/details/:accountId': true,
        '/accounts/details/:accountId/movements': true,
        '/accounts/welcome': false,
        '/accounts/tabs/overview': true,
        '/sign-in': null,
      });
    });

    test('When the owner of a full path is looked up, '
        'Then nested and grouped routes name their micro app', () async {
      // Given
      final container = await _bootstrap({
        'accounts': tree,
        'transfers': [_route('/transfers')],
      });

      // When
      final owners = [
        container.microAppIdOf('/accounts/details/:accountId/movements'),
        container.microAppIdOf('/accounts/tabs/overview'),
        container.microAppIdOf('/transfers'),
        container.microAppIdOf('/missing'),
      ];

      // Then
      expect(owners, ['accounts', 'accounts', 'transfers', null]);
    });
  });

  group('Given route trees that break a rule', () {
    test('When the same full path is declared twice, '
        'Then startup stops naming the path and the micro app', () {
      // Given: once nested, once at the top level. (The prefix rule keeps
      // two micro apps from ever declaring the same path.)
      final routesByMicroApp = {
        'accounts': [
          _route('/accounts', routes: [_route('shared')]),
          _route('/accounts/shared'),
        ],
        'transfers': [_route('/transfers')],
      };

      // When
      final bootstrapping = _bootstrap(routesByMicroApp);

      // Then
      expect(
        bootstrapping,
        _startupFailure(ModularAppStartupExceptionType.duplicateRoutePath, [
          '/accounts/shared',
          '"accounts"',
        ]),
      );
    });

    test('When two full paths differ only in parameter names, '
        'Then startup stops as for a duplicate', () {
      // Given
      final routesByMicroApp = {
        'accounts': [_route('/accounts/:id'), _route('/accounts/:accountId')],
      };

      // When
      final bootstrapping = _bootstrap(routesByMicroApp);

      // Then
      expect(
        bootstrapping,
        _startupFailure(ModularAppStartupExceptionType.duplicateRoutePath, [
          '/accounts/:accountId',
        ]),
      );
    });

    test('When a top-level path lacks the micro app prefix, '
        'Then startup stops naming the path', () {
      // Given
      final routesByMicroApp = {
        'accounts': [_route('/home')],
      };

      // When
      final bootstrapping = _bootstrap(routesByMicroApp);

      // Then
      expect(
        bootstrapping,
        _startupFailure(ModularAppStartupExceptionType.invalidRoutePath, [
          '/home',
          '/accounts',
        ]),
      );
    });

    test('When a path only shares the prefix text, '
        'Then startup stops naming the path', () {
      // Given
      final routesByMicroApp = {
        'accounts': [_route('/accountsettings')],
      };

      // When
      final bootstrapping = _bootstrap(routesByMicroApp);

      // Then
      expect(
        bootstrapping,
        _startupFailure(ModularAppStartupExceptionType.invalidRoutePath, [
          '/accountsettings',
        ]),
      );
    });

    test('When a grouped path lacks the micro app prefix, '
        'Then startup stops naming the path', () {
      // Given
      final routesByMicroApp = {
        'accounts': [
          MicroAppRouteGroup(
            builder: (context, child) => child,
            routes: [_route('/tabs/overview')],
          ),
        ],
      };

      // When
      final bootstrapping = _bootstrap(routesByMicroApp);

      // Then
      expect(
        bootstrapping,
        _startupFailure(ModularAppStartupExceptionType.invalidRoutePath, [
          '/tabs/overview',
        ]),
      );
    });

    test('When a nested path is absolute, '
        'Then startup stops naming the path', () {
      // Given
      final routesByMicroApp = {
        'accounts': [
          _route('/accounts', routes: [_route('/accounts/details')]),
        ],
      };

      // When
      final bootstrapping = _bootstrap(routesByMicroApp);

      // Then
      expect(
        bootstrapping,
        _startupFailure(ModularAppStartupExceptionType.invalidRoutePath, [
          '/accounts/details',
        ]),
      );
    });

    test('When a full path repeats a parameter name, '
        'Then startup stops naming the path and the parameter', () {
      // Given
      final routesByMicroApp = {
        'accounts': [
          _route('/accounts/:id', routes: [_route('cards/:id')]),
        ],
      };

      // When
      final bootstrapping = _bootstrap(routesByMicroApp);

      // Then
      expect(
        bootstrapping,
        _startupFailure(ModularAppStartupExceptionType.repeatedPathParameter, [
          '/accounts/:id/cards/:id',
          '"id"',
        ]),
      );
    });
  });

  group('Given host routes next to the micro apps\' routes', () {
    final accounts = {
      'accounts': [_route('/accounts')],
    };

    test('When a nested host route hangs off the root, '
        'Then startup accepts it with its full path', () async {
      // Given
      final hostRoutes = [
        _route(
          '/',
          requiresAuthentication: false,
          routes: [_route('sign-in', requiresAuthentication: false)],
        ),
      ];

      // When
      final container = await _bootstrap(accounts, hostRoutes: hostRoutes);

      // Then
      expect(container.requiresAuthentication('/sign-in'), isFalse);
      expect(container.microAppIdOf('/sign-in'), isNull);
    });

    test('When there are no micro apps, '
        'Then a host route may start with a parameter', () async {
      // Given
      final hostRoutes = [_route('/:slug', requiresAuthentication: false)];

      // When
      final container = await _bootstrap({}, hostRoutes: hostRoutes);

      // Then
      expect(container.routes, hostRoutes);
    });
  });

  group('Given host routes that break a rule', () {
    final accounts = {
      'accounts': [_route('/accounts')],
    };

    test('When a host route is inside a micro app\'s namespace, '
        'Then startup stops naming the path and the micro app', () {
      // Given
      final hostRoutes = [_route('/accounts/promo')];

      // When
      final bootstrapping = _bootstrap(accounts, hostRoutes: hostRoutes);

      // Then
      expect(
        bootstrapping,
        _startupFailure(ModularAppStartupExceptionType.reservedRoutePath, [
          '/accounts/promo',
          '"accounts"',
        ]),
      );
    });

    test('When a host route starts with a parameter, '
        'Then startup stops, because it would match every micro app', () {
      // Given
      final hostRoutes = [
        _route('/', routes: [_route(':slug')]),
      ];

      // When
      final bootstrapping = _bootstrap(accounts, hostRoutes: hostRoutes);

      // Then
      expect(
        bootstrapping,
        _startupFailure(ModularAppStartupExceptionType.reservedRoutePath, [
          '/:slug',
          '"accounts"',
        ]),
      );
    });

    test('When a top-level host path has no leading slash, '
        'Then startup stops naming the path and the host', () {
      // Given
      final hostRoutes = [_route('sign-in')];

      // When
      final bootstrapping = _bootstrap(accounts, hostRoutes: hostRoutes);

      // Then
      expect(
        bootstrapping,
        _startupFailure(ModularAppStartupExceptionType.invalidRoutePath, [
          'sign-in',
          'the host',
        ]),
      );
    });

    test('When a nested host path has a leading slash, '
        'Then startup stops naming the path and the host', () {
      // Given
      final hostRoutes = [
        _route('/settings', routes: [_route('/privacy')]),
      ];

      // When
      final bootstrapping = _bootstrap(accounts, hostRoutes: hostRoutes);

      // Then
      expect(
        bootstrapping,
        _startupFailure(ModularAppStartupExceptionType.invalidRoutePath, [
          '/privacy',
          'the host',
        ]),
      );
    });

    test('When two host routes share a full path, '
        'Then startup stops naming the path and the host', () {
      // Given
      final hostRoutes = [
        _route('/', routes: [_route('help')]),
        _route('/help'),
      ];

      // When
      final bootstrapping = _bootstrap(accounts, hostRoutes: hostRoutes);

      // Then
      expect(
        bootstrapping,
        _startupFailure(ModularAppStartupExceptionType.duplicateRoutePath, [
          '/help',
          'the host',
        ]),
      );
    });

    test('When a host full path repeats a parameter name, '
        'Then startup stops naming the path and the parameter', () {
      // Given
      final hostRoutes = [
        _route('/promo/:id', routes: [_route('items/:id')]),
      ];

      // When
      final bootstrapping = _bootstrap(accounts, hostRoutes: hostRoutes);

      // Then
      expect(
        bootstrapping,
        _startupFailure(ModularAppStartupExceptionType.repeatedPathParameter, [
          '/promo/:id/items/:id',
          'the host',
        ]),
      );
    });
  });
}

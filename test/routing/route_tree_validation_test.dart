// Feature: Route trees are checked at startup (contracts/routing.md, "Path
// rules" and "Startup checks"; data-model.md MicroAppRoute.path,
// MicroAppRoute.requiresAuthentication, MicroAppRoute.routes, and
// MicroAppRouteGroup.routes).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';

import '../support/reference_route_validation.dart';
import '../support/reference_startup_exception.dart';

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

Matcher _startupFailureNaming(List<String> culprits) => throwsA(
  isA<ReferenceStartupException>().having(
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

    test('When it is flattened, Then child paths join to their parents', () {
      // Given
      final routes = tree;

      // When
      final paths = ReferenceRouteValidation.flatten(routes)
          .map((entry) => entry.fullPath);

      // Then
      expect(paths, [
        '/accounts',
        '/accounts/details/:accountId',
        '/accounts/details/:accountId/movements',
        '/accounts/welcome',
        '/accounts/tabs/overview',
      ]);
    });

    test('When it is flattened, '
        'Then the sign-in requirement is inherited from ancestors', () {
      // Given
      final routes = tree;

      // When
      final requiresAuth = {
        for (final entry in ReferenceRouteValidation.flatten(routes))
          entry.fullPath: entry.requiresAuthentication,
      };

      // Then
      expect(requiresAuth, {
        '/accounts': true,
        // Opts out, but '/accounts' requires sign-in.
        '/accounts/details/:accountId': true,
        '/accounts/details/:accountId/movements': true,
        '/accounts/welcome': false,
        '/accounts/tabs/overview': true,
      });
    });

    test('When it is validated for its micro app, Then it passes', () {
      // Given
      final routesByMicroApp = {'accounts': tree};

      // When
      final entries = ReferenceRouteValidation.validate(routesByMicroApp);

      // Then
      expect(entries, hasLength(5));
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
      void validate() => ReferenceRouteValidation.validate(routesByMicroApp);

      // Then
      expect(
        validate,
        _startupFailureNaming(['/accounts/shared', '"accounts"']),
      );
    });

    test('When two full paths differ only in parameter names, '
        'Then startup stops as for a duplicate', () {
      // Given
      final routesByMicroApp = {
        'accounts': [_route('/accounts/:id'), _route('/accounts/:accountId')],
      };

      // When
      void validate() => ReferenceRouteValidation.validate(routesByMicroApp);

      // Then
      expect(validate, _startupFailureNaming(['/accounts/:accountId']));
    });

    test('When a top-level path lacks the micro app prefix, '
        'Then startup stops naming the path', () {
      // Given
      final routesByMicroApp = {
        'accounts': [_route('/home')],
      };

      // When
      void validate() => ReferenceRouteValidation.validate(routesByMicroApp);

      // Then
      expect(validate, _startupFailureNaming(['/home', '/accounts']));
    });

    test('When a path only shares the prefix text, '
        'Then startup stops naming the path', () {
      // Given
      final routesByMicroApp = {
        'accounts': [_route('/accountsettings')],
      };

      // When
      void validate() => ReferenceRouteValidation.validate(routesByMicroApp);

      // Then
      expect(validate, _startupFailureNaming(['/accountsettings']));
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
      void validate() => ReferenceRouteValidation.validate(routesByMicroApp);

      // Then
      expect(validate, _startupFailureNaming(['/tabs/overview']));
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
      void validate() => ReferenceRouteValidation.validate(routesByMicroApp);

      // Then
      expect(validate, _startupFailureNaming(['/accounts/details']));
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
      void validate() => ReferenceRouteValidation.validate(routesByMicroApp);

      // Then
      expect(
        validate,
        _startupFailureNaming(['/accounts/:id/cards/:id', '"id"']),
      );
    });
  });
}

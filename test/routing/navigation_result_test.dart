// Feature: Navigation outcomes and navigation exceptions (FR-023;
// contracts/routing.md; data-model.md NavigationResult.result).
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';

/// Matches every outcome of `push` and `replace` without a default branch.
String describe(Result<NavigationResult, NavigationException> outcome) =>
    switch (outcome) {
      Ok(value: RouteCompleted(:final result)) => 'completed:$result',
      Ok(value: RouteCancelled()) => 'cancelled',
      Err(failure: RouteNotFoundException(:final path)) => 'not found:$path',
    };

void main() {
  group('Given each outcome a push can complete with', () {
    const outcomes = <Result<NavigationResult, NavigationException>>[
      Ok(RouteCompleted({'accountId': 'a1'})),
      Ok(RouteCancelled()),
      Err(RouteNotFoundException('/accounts/unknown')),
    ];

    test('When they are matched exhaustively, '
        'Then each lands in its own branch', () {
      // When
      final descriptions = outcomes.map(describe).toList();

      // Then
      expect(descriptions, [
        'completed:{accountId: a1}',
        'cancelled',
        'not found:/accounts/unknown',
      ]);
    });
  });

  group('Given a location that matches no route', () {
    const exception = RouteNotFoundException('/accounts/statements');

    test('When the exception is read, '
        'Then it is an Exception that names the requested path', () {
      // When
      final path = exception.path;

      // Then
      expect(path, '/accounts/statements');
      expect(exception, isA<Exception>());
      expect(exception, isA<NavigationException>());
    });
  });

  group('Given two outcomes built separately with the same content', () {
    final completed = RouteCompleted({'accountId': 'a1', 'primary': true});
    final sameCompleted = RouteCompleted({'primary': true, 'accountId': 'a1'});

    test('When they are compared, '
        'Then the result maps are compared by content', () {
      // When
      final completedEqual = completed == sameCompleted;

      // Then
      expect(completedEqual, isTrue);
      expect(completed.hashCode, sameCompleted.hashCode);
      // ignore: prefer_const_constructors
      expect(RouteCancelled(), const RouteCancelled());
      expect(
        // ignore: prefer_const_constructors
        RouteNotFoundException('/x'),
        const RouteNotFoundException('/x'),
      );
      expect(
        const RouteNotFoundException('/x') ==
            const RouteNotFoundException('/y'),
        isFalse,
      );
    });
  });
}

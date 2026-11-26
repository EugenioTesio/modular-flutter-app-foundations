// Feature: Foundations, the design system, and switchable_state export no
// clashing names (contracts/public-surface.md, "Rules"). A clash would be an
// ambiguous_export compile error in this file, so compiling it is the check.
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';

void main() {
  group('Given the single Foundations import', () {
    test('When one symbol from each delivered source is referenced, '
        'Then all three resolve through foundations.dart', () {
      // Given: one symbol from each source, all through foundations.dart.
      const endpoint = InterModuleEndpoint(url: '/accounts/v1/balance');
      final declaration = AppState<int>(() => 0, debugName: 'count');

      // When
      final resolved = (endpoint.url, DsSpacing.md, declaration.debugName);

      // Then
      expect(resolved, ('/accounts/v1/balance', 16.0, 'count'));
    });
  });
}

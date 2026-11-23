// Feature: DsPageScaffold lays out every screen the same way (contracts/
// design-system.md, D1–D4; data-model.md Design System row "Templates").
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/a11y_harness.dart';

Widget _app(Widget home) => MaterialApp(theme: DsTheme.light(), home: home);

void main() {
  group('Given a DsPageScaffold', () {
    DsA11yHarness.describeRules({
      'with a body and a primary action': () => DsPageScaffold(
        title: 'New transfer to a saved recipient',
        body: const Text('Choose who receives the money.'),
        primaryAction: DsButton(label: 'Continue', onPressed: () {}),
        onBack: () {},
      ),
      'with a body only': () => const DsPageScaffold(
        title: 'Accounts',
        body: Text('No accounts yet.'),
      ),
    }, scrollable: false);

    testWidgets('When it is built, Then it shows the title and pads the body '
        'by DsSpacing.md', (tester) async {
      // Given
      const page = DsPageScaffold(
        title: 'Accounts',
        body: SizedBox.expand(key: Key('body')),
      );

      // When
      await tester.pumpWidget(_app(page));

      // Then
      expect(find.text('Accounts'), findsOneWidget);
      final body = tester.getRect(find.byKey(const Key('body')));
      final scaffold = tester.getRect(find.byType(DsPageScaffold));
      expect(body.left - scaffold.left, DsSpacing.md);
      expect(scaffold.right - body.right, DsSpacing.md);
    });

    testWidgets('When it has a primary action, '
        'Then the action is pinned at the bottom at full width', (
      tester,
    ) async {
      // Given
      final page = DsPageScaffold(
        title: 'Transfer',
        body: const SizedBox.shrink(),
        primaryAction: DsButton(label: 'Continue', onPressed: () {}),
      );

      // When
      await tester.pumpWidget(_app(page));

      // Then
      final scaffold = tester.getRect(find.byType(DsPageScaffold));
      final action = tester.getRect(find.byType(DsButton));
      expect(action.width, scaffold.width - 2 * DsSpacing.md);
      expect(scaffold.bottom - action.bottom, DsSpacing.md);
    });

    testWidgets('When onBack is set and back is tapped, Then onBack runs', (
      tester,
    ) async {
      // Given
      var backs = 0;
      await tester.pumpWidget(
        _app(
          DsPageScaffold(
            title: 'Details',
            body: const SizedBox(),
            onBack: () => backs++,
          ),
        ),
      );

      // When
      await tester.tap(find.byType(BackButton));
      await tester.pump();

      // Then
      expect(backs, 1);
    });

    testWidgets('When onBack is null on a pushed route, '
        'Then the platform back button pops it', (tester) async {
      // Given
      await tester.pumpWidget(
        _app(const DsPageScaffold(title: 'Home', body: SizedBox())),
      );
      expect(find.byType(BackButton), findsNothing);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              const DsPageScaffold(title: 'Details', body: SizedBox()),
        ),
      );
      await tester.pumpAndSettle();

      // When
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Then
      expect(find.text('Details'), findsNothing);
      expect(find.text('Home'), findsOneWidget);
    });
  });
}

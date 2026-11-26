// Feature: DsEmptyState explains an empty area, with or without an action
// (contracts/design-system.md, D1–D4; data-model.md Design System row
// "Molecules").
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/a11y_harness.dart';

void main() {
  group('Given a DsEmptyState', () {
    DsA11yHarness.describeRules({
      'without an action': () => const DsEmptyState(
        icon: Icons.receipt_long,
        title: 'No transfers yet',
        message: 'Transfers you make appear here.',
      ),
      'with an action': () => DsEmptyState(
        icon: Icons.receipt_long,
        title: 'No transfers yet',
        message: 'Transfers you make appear here.',
        actionLabel: 'New transfer',
        onAction: () {},
      ),
    });

    testWidgets('When it has no action, Then it shows no button', (
      tester,
    ) async {
      // Given
      const state = DsEmptyState(title: 'No transfers yet');

      // When
      await DsA11yHarness.pump(tester, state, theme: DsTheme.light());

      // Then
      expect(find.byType(DsButton), findsNothing);
      expect(find.text('No transfers yet'), findsOneWidget);
    });

    testWidgets('When its action is tapped, '
        'Then onAction runs and the title is a heading', (tester) async {
      // Given
      var taps = 0;
      await DsA11yHarness.pump(
        tester,
        DsEmptyState(
          title: 'No transfers yet',
          icon: Icons.receipt_long,
          actionLabel: 'New transfer',
          onAction: () => taps++,
        ),
        theme: DsTheme.light(),
      );
      final semantics = tester.ensureSemantics();

      // When
      await tester.tap(find.text('New transfer'));
      await tester.pump();

      // Then
      expect(taps, 1);
      expect(
        tester
            .getSemantics(find.text('No transfers yet'))
            .flagsCollection
            .isHeader,
        isTrue,
      );
      semantics.dispose();
    });
  });
}

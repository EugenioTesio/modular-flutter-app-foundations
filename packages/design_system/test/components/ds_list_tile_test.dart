// Feature: DsListTile shows one accessible list row (contracts/
// design-system.md, D1–D4; data-model.md Design System row "Molecules").
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/a11y_harness.dart';

void main() {
  group('Given a DsListTile', () {
    DsA11yHarness.describeRules({
      'a title only': () => const DsListTile(title: 'Checking'),
      'tappable with every slot': () => DsListTile(
        title: 'Everyday checking account with a long name',
        subtitle: '•••• 4821 · Opened in 2019 at the downtown branch',
        leading: const Icon(Icons.account_balance),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    });

    testWidgets('When a tappable row is tapped, '
        'Then onTap runs and the row is labeled by its text', (tester) async {
      // Given
      var taps = 0;
      await DsA11yHarness.pump(
        tester,
        DsListTile(
          title: 'Checking',
          subtitle: '•••• 4821',
          onTap: () => taps++,
        ),
        theme: DsTheme.light(),
      );

      // When
      await tester.tap(find.byType(DsListTile));
      await tester.pump();

      // Then
      expect(taps, 1);
      expect(find.bySemanticsLabel(RegExp('Checking')), findsOneWidget);
    });

    testWidgets('When it is built, Then the title uses textPrimary and the '
        'subtitle textSecondary', (tester) async {
      // Given
      final colors = DsTheme.light().extension<DsColors>()!;

      // When
      await DsA11yHarness.pump(
        tester,
        const DsListTile(title: 'Checking', subtitle: '•••• 4821'),
        theme: DsTheme.light(),
      );

      // Then
      expect(
        tester.widget<Text>(find.text('Checking')).style!.color,
        colors.textPrimary,
      );
      expect(
        tester.widget<Text>(find.text('•••• 4821')).style!.color,
        colors.textSecondary,
      );
    });
  });
}

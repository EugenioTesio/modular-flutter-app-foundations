// Feature: DsCard groups content and, when tappable, is one labeled target
// (contracts/design-system.md, D1–D4; data-model.md Design System row
// "Molecules").
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/a11y_harness.dart';

void main() {
  group('Given a DsCard', () {
    DsA11yHarness.describeRules({
      'static': () => const DsCard(child: Text('Checking account')),
      'tappable with a label': () => DsCard(
        onTap: () {},
        semanticsLabel: 'Checking account, balance 1,250',
        child: const Text('Checking account'),
      ),
      'tappable without a label': () =>
          DsCard(onTap: () {}, child: const Text('Savings account')),
    });

    testWidgets('When a tappable card is tapped, '
        'Then onTap runs and screen readers see one labeled button', (
      tester,
    ) async {
      // Given
      var taps = 0;
      await DsA11yHarness.pump(
        tester,
        DsCard(
          onTap: () => taps++,
          semanticsLabel: 'Open checking',
          child: const Column(children: [Text('Checking'), Text('1,250')]),
        ),
        theme: DsTheme.light(),
      );

      // When
      await tester.tap(find.byType(DsCard));
      await tester.pump();

      // Then
      expect(taps, 1);
      expect(find.bySemanticsLabel('Open checking'), findsOneWidget);
      expect(find.bySemanticsLabel('1,250'), findsNothing);
      expect(tester.getSize(find.byType(DsCard)).height, greaterThan(47.9));
    });

    testWidgets('When a card is built, '
        'Then it uses the surface and border roles', (tester) async {
      // Given
      final colors = DsTheme.dark().extension<DsColors>()!;

      // When
      await DsA11yHarness.pump(
        tester,
        const DsCard(child: Text('Checking')),
        theme: DsTheme.dark(),
      );

      // Then
      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(DsCard),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, colors.surface);
      expect((material.shape! as OutlinedBorder).side.color, colors.border);
    });
  });
}

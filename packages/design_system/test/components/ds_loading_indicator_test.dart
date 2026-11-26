// Feature: DsLoadingIndicator announces what is loading (contracts/
// design-system.md, D3, D4, and D6; data-model.md Design System row "Atoms").
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/a11y_harness.dart';

void main() {
  group('Given a DsLoadingIndicator', () {
    DsA11yHarness.describeRules({
      'spinning': () =>
          const DsLoadingIndicator(semanticsLabel: 'Loading accounts'),
    });

    testWidgets('When it is built, Then it announces its label, has the '
        'given size, and uses actionPrimary', (tester) async {
      // Given
      final colors = DsTheme.dark().extension<DsColors>()!;

      // When
      await DsA11yHarness.pump(
        tester,
        const Center(
          child: DsLoadingIndicator(semanticsLabel: 'Loading', size: 40),
        ),
        theme: DsTheme.dark(),
      );

      // Then
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      expect(
        tester.getSize(find.byType(DsLoadingIndicator)),
        const Size(40, 40),
      );
      final spinner = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(spinner.color, colors.actionPrimary);
    });
  });
}

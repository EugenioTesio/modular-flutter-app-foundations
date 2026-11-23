// Feature: DsButton is accessible in every variant and state
// (contracts/design-system.md, D1–D6 and D8; data-model.md Design System row
// "Atoms").
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/a11y_harness.dart';

void _noop() {}

Material _materialOf(WidgetTester tester) => tester.widget<Material>(
  find.descendant(of: find.byType(DsButton), matching: find.byType(Material)),
);

void main() {
  group('Given a DsButton', () {
    DsA11yHarness.describeRules({
      'primary': () => const DsButton(label: 'Continue', onPressed: _noop),
      'secondary': () => const DsButton(
        label: 'Cancel',
        onPressed: _noop,
        variant: DsButtonVariant.secondary,
      ),
      'tertiary': () => const DsButton(
        label: 'Skip',
        onPressed: _noop,
        variant: DsButtonVariant.tertiary,
      ),
      'primary with an icon and a long label': () => const DsButton(
        label: 'Send the transfer to a saved recipient',
        icon: Icons.send,
        onPressed: _noop,
        expand: true,
      ),
      'disabled': () => const DsButton(label: 'Continue', onPressed: null),
      'loading': () =>
          const DsButton(label: 'Continue', onPressed: _noop, isLoading: true),
    });
  });

  group('Given a disabled DsButton', () {
    testWidgets('When it is tapped, Then nothing happens and it uses the '
        'disabled roles', (tester) async {
      // Given
      final colors = DsTheme.light().extension<DsColors>()!;
      await DsA11yHarness.pump(
        tester,
        const DsButton(label: 'Continue', onPressed: null),
        theme: DsTheme.light(),
      );

      // When
      await tester.tap(find.byType(DsButton), warnIfMissed: false);
      await tester.pump();

      // Then
      final material = _materialOf(tester);
      expect(material.color, colors.actionDisabled);
      expect(material.textStyle!.color, colors.textDisabled);
      expect(
        tester
            .getSemantics(find.byType(DsButton))
            .flagsCollection
            .isEnabled
            .toBoolOrNull(),
        isFalse,
      );
    });
  });

  group('Given a DsButton that becomes busy', () {
    testWidgets('When it is loading, Then it ignores taps, keeps its size, '
        'keeps its label, and keeps the enabled colors', (tester) async {
      // Given
      var taps = 0;
      final colors = DsTheme.light().extension<DsColors>()!;
      await DsA11yHarness.pump(
        tester,
        DsButton(label: 'Continue', onPressed: () => taps++),
        theme: DsTheme.light(),
      );
      final idleSize = tester.getSize(find.byType(DsButton));

      // When
      await DsA11yHarness.pump(
        tester,
        DsButton(label: 'Continue', onPressed: () => taps++, isLoading: true),
        theme: DsTheme.light(),
      );
      await tester.tap(find.byType(DsButton), warnIfMissed: false);
      await tester.pump();

      // Then
      expect(taps, 0);
      expect(tester.getSize(find.byType(DsButton)), idleSize);
      expect(find.bySemanticsLabel('Continue'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(_materialOf(tester).color, colors.actionPrimary);
    });
  });

  group('Given an enabled DsButton', () {
    testWidgets('When it is tapped, Then onPressed runs once', (tester) async {
      // Given
      var taps = 0;
      await DsA11yHarness.pump(
        tester,
        DsButton(label: 'Continue', onPressed: () => taps++),
        theme: DsTheme.light(),
      );

      // When
      await tester.tap(find.byType(DsButton));
      await tester.pump();

      // Then
      expect(taps, 1);
    });

    testWidgets('When each variant is built, Then only primary is filled and '
        'only secondary is outlined', (tester) async {
      // Given
      final colors = DsTheme.light().extension<DsColors>()!;
      final looks = <DsButtonVariant, (Color?, BorderSide)>{};

      // When
      for (final variant in DsButtonVariant.values) {
        await DsA11yHarness.pump(
          tester,
          DsButton(label: 'Go', onPressed: _noop, variant: variant),
          theme: DsTheme.light(),
        );
        final material = _materialOf(tester);
        looks[variant] = (
          material.color,
          (material.shape! as OutlinedBorder).side,
        );
      }

      // Then
      expect(looks[DsButtonVariant.primary]!.$1, colors.actionPrimary);
      expect(looks[DsButtonVariant.secondary]!.$1, Colors.transparent);
      expect(looks[DsButtonVariant.secondary]!.$2.color, colors.actionPrimary);
      expect(looks[DsButtonVariant.tertiary]!.$2, BorderSide.none);
    });

    testWidgets('When expand is set, Then it fills the available width', (
      tester,
    ) async {
      // Given
      const button = DsButton(label: 'Go', onPressed: _noop, expand: true);

      // When
      await DsA11yHarness.pump(tester, button, theme: DsTheme.light());

      // Then
      final width = tester.getSize(find.byType(DsButton)).width;
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(width, screen.width - 2 * DsSpacing.md);
    });
  });
}

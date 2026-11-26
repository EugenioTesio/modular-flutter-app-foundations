// Feature: DsTextField labels, guides, and reports errors accessibly
// (contracts/design-system.md, D1–D5 and D7; data-model.md Design System row
// "Atoms").
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/a11y_harness.dart';

void main() {
  group('Given a DsTextField', () {
    DsA11yHarness.describeRules({
      'labeled': () => const DsTextField(label: 'Email'),
      'showing a hint and helper text': () => const DsTextField(
        label: 'Email',
        hint: 'name@example.com',
        helperText: 'We send the receipt to this address.',
      ),
      'showing an error': () => const DsTextField(
        label: 'Amount',
        errorText: 'Enter an amount greater than zero.',
      ),
      'disabled': () => const DsTextField(label: 'Email', enabled: false),
    });
  });

  group('Given a DsTextField with an error', () {
    testWidgets('When it is built, Then the error shows in errorForeground '
        'and is exposed to screen readers', (tester) async {
      // Given
      final colors = DsTheme.light().extension<DsColors>()!;
      const error = 'Enter an amount greater than zero.';

      // When
      await DsA11yHarness.pump(
        tester,
        const DsTextField(label: 'Amount', errorText: error),
        theme: DsTheme.light(),
      );

      // Then
      final text = tester.widget<Text>(find.text(error));
      final style = DefaultTextStyle.of(tester.element(find.text(error))).style
          .merge(text.style);
      expect(style.color, colors.errorForeground);
      expect(find.bySemanticsLabel(RegExp(error)), findsWidgets);
    });
  });

  group('Given a disabled DsTextField', () {
    testWidgets('When it is tapped, Then it takes no focus and uses the '
        'disabled roles', (tester) async {
      // Given
      final colors = DsTheme.light().extension<DsColors>()!;
      await DsA11yHarness.pump(
        tester,
        const DsTextField(label: 'Email', enabled: false),
        theme: DsTheme.light(),
      );

      // When
      await tester.tap(find.byType(DsTextField), warnIfMissed: false);
      await tester.pump();

      // Then
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration!.fillColor, colors.actionDisabled);
      expect(field.style!.color, colors.textDisabled);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isFalse,
      );
    });
  });

  group('Given an enabled DsTextField', () {
    testWidgets('When the user types, Then onChanged receives the text', (
      tester,
    ) async {
      // Given
      final changes = <String>[];
      await DsA11yHarness.pump(
        tester,
        DsTextField(label: 'Email', onChanged: changes.add),
        theme: DsTheme.light(),
      );

      // When
      await tester.enterText(find.byType(DsTextField), 'a@b.co');

      // Then
      expect(changes, ['a@b.co']);
      expect(find.bySemanticsLabel('Email'), findsOneWidget);
    });
  });
}

// Feature: DsInlineMessage shows each tone in its own roles (contracts/
// design-system.md, D1–D4 and D9; data-model.md Design System row
// "Molecules").
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/a11y_harness.dart';

(Color, Color) _rolesFor(DsMessageTone tone, DsColors c) => switch (tone) {
  DsMessageTone.info => (c.infoBackground, c.infoForeground),
  DsMessageTone.success => (c.successBackground, c.successForeground),
  DsMessageTone.warning => (c.warningBackground, c.warningForeground),
  DsMessageTone.error => (c.errorBackground, c.errorForeground),
};

void main() {
  group('Given a DsInlineMessage', () {
    DsA11yHarness.describeRules({
      for (final tone in DsMessageTone.values)
        'a ${tone.name} message with a title and an action': () =>
            DsInlineMessage(
              tone: tone,
              title: 'Balance unavailable',
              message: 'Check your connection and try again in a minute.',
              actionLabel: 'Retry',
              onAction: () {},
            ),
      'a message only': () =>
          const DsInlineMessage(message: 'Transfers made today appear here.'),
    });

    for (final (name, theme) in DsA11yHarness.themes) {
      testWidgets('When each tone is built in the $name theme, '
          'Then it uses its matching background and foreground roles', (
        tester,
      ) async {
        // Given
        final colors = theme.extension<DsColors>()!;

        for (final tone in DsMessageTone.values) {
          // When
          await DsA11yHarness.pump(
            tester,
            DsInlineMessage(tone: tone, message: 'Message ${tone.name}'),
            theme: theme,
          );

          // Then
          final (background, foreground) = _rolesFor(tone, colors);
          final box = tester.widget<DecoratedBox>(
            find.descendant(
              of: find.byType(DsInlineMessage),
              matching: find.byType(DecoratedBox),
            ),
          );
          expect((box.decoration as BoxDecoration).color, background);
          expect(
            tester.widget<Text>(find.text('Message ${tone.name}')).style!.color,
            foreground,
          );
          expect(tester.widget<Icon>(find.byType(Icon)).color, foreground);
        }
      });
    }

    testWidgets('When its action is tapped, Then onAction runs', (
      tester,
    ) async {
      // Given
      var taps = 0;
      await DsA11yHarness.pump(
        tester,
        DsInlineMessage(
          message: 'Offline',
          actionLabel: 'Retry',
          onAction: () => taps++,
        ),
        theme: DsTheme.light(),
      );

      // When
      await tester.tap(find.text('Retry'));
      await tester.pump();

      // Then
      expect(taps, 1);
    });
  });
}

// Feature: One brand configuration restyles every component (data-model.md
// Design System row "Brand"; contracts/design-system.md rule D8).
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _green = Color(0xFF0B6E4F);

Color _fillOf(WidgetTester tester) {
  final material = tester.widget<Material>(
    find.descendant(of: find.byType(DsButton), matching: find.byType(Material)),
  );
  return material.color!;
}

Future<void> _pumpButton(WidgetTester tester, ThemeData theme) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Center(
          child: DsButton(label: 'Pay', onPressed: () {}),
        ),
      ),
    ),
  );
  // MaterialApp animates theme changes; wait for the new theme.
  await tester.pumpAndSettle();
}

void main() {
  group('Given a brand whose primary color has enough contrast', () {
    const brand = DsBrand(primary: _green);

    test('When the light theme is built, '
        'Then the action and focus roles use the brand color unchanged', () {
      // Given
      final standard = DsTheme.light().extension<DsColors>()!;

      // When
      final branded = DsTheme.light(brand: brand).extension<DsColors>()!;

      // Then
      expect(branded.actionPrimary, _green);
      expect(branded.focus, _green);
      expect(standard.actionPrimary, isNot(_green));
      expect(standard.focus, isNot(_green));
    });

    testWidgets('When a primary DsButton is built under each brand, '
        'Then its fill follows the brand with no component change', (
      tester,
    ) async {
      // Given
      await _pumpButton(tester, DsTheme.light());
      final standardFill = _fillOf(tester);

      // When
      await _pumpButton(tester, DsTheme.light(brand: brand));
      final brandedFill = _fillOf(tester);

      // Then
      expect(standardFill, DsBrand.standard.primary);
      expect(brandedFill, _green);
    });

    testWidgets('When a DsButton has focus, '
        'Then its focus ring uses the brand-derived focus role', (
      tester,
    ) async {
      // Given
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await _pumpButton(tester, DsTheme.light(brand: brand));

      // When
      Focus.of(tester.element(find.text('Pay'))).requestFocus();
      await tester.pumpAndSettle();

      // Then
      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(DsButton),
          matching: find.byType(Material),
        ),
      );
      final shape = material.shape! as OutlinedBorder;
      expect(shape.side.color, _green);
      expect(shape.side.width, 2);
    });
  });

  group('Given a brand with or without a font family', () {
    test('When no font family is set, '
        'Then the typography falls back to the platform font', () {
      // Given
      const brand = DsBrand(primary: _green);

      // When
      final theme = DsTheme.light(brand: brand);

      // Then
      final typography = theme.extension<DsTypography>()!;
      expect(typography.body.fontFamily, isNull);
      expect(typography.title.fontFamily, isNull);
      // Material's text theme keeps the platform's own font.
      expect(
        theme.textTheme.bodyLarge!.fontFamily,
        ThemeData.light().textTheme.bodyLarge!.fontFamily,
      );
    });

    test('When a font family is set, Then every style uses it', () {
      // Given
      const brand = DsBrand(primary: _green, fontFamily: 'BrandSans');

      // When
      final typography = DsTheme.dark(brand: brand).extension<DsTypography>()!;

      // Then
      expect(
        [
          typography.display,
          typography.headline,
          typography.title,
          typography.body,
          typography.bodyStrong,
          typography.label,
          typography.caption,
        ].map((style) => style.fontFamily),
        everyElement('BrandSans'),
      );
    });
  });
}

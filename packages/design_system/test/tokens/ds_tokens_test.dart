// Feature: Design tokens hold fixed steps and readable color roles
// (data-model.md Design System rows "Primitive tokens" and "Semantic tokens";
// contracts/design-system.md, "Tokens" and the contrast rule).
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

/// Every (foreground, background) pair that must reach 4.5:1, by name.
Map<String, (Color, Color)> _textPairs(DsColors c) => {
  for (final (name, text) in [
    ('textPrimary', c.textPrimary),
    ('textSecondary', c.textSecondary),
  ])
    for (final (surfaceName, surface) in [
      ('background', c.background),
      ('surface', c.surface),
      ('surfaceVariant', c.surfaceVariant),
    ])
      '$name on $surfaceName': (text, surface),
  'textOnAction on actionPrimary': (c.textOnAction, c.actionPrimary),
  'textOnAction on actionPrimaryPressed': (
    c.textOnAction,
    c.actionPrimaryPressed,
  ),
  'actionPrimary on background': (c.actionPrimary, c.background),
  'actionPrimary on surface': (c.actionPrimary, c.surface),
  'infoForeground on infoBackground': (c.infoForeground, c.infoBackground),
  'successForeground on successBackground': (
    c.successForeground,
    c.successBackground,
  ),
  'warningForeground on warningBackground': (
    c.warningForeground,
    c.warningBackground,
  ),
  'errorForeground on errorBackground': (c.errorForeground, c.errorBackground),
  'errorForeground on background': (c.errorForeground, c.background),
  'errorForeground on surface': (c.errorForeground, c.surface),
};

void main() {
  group('Given the primitive tokens', () {
    test('When the spacing steps are read, '
        'Then they are 4, 8, 12, 16, 24, 32, and 48', () {
      // Given
      const steps = [
        DsSpacing.xxs,
        DsSpacing.xs,
        DsSpacing.sm,
        DsSpacing.md,
        DsSpacing.lg,
        DsSpacing.xl,
        DsSpacing.xxl,
      ];

      // When
      final values = steps.toList();

      // Then
      expect(values, [4, 8, 12, 16, 24, 32, 48]);
    });

    test('When the radii are read, Then they are 4, 8, 16, and pill', () {
      // Given
      const radii = [DsRadius.sm, DsRadius.md, DsRadius.lg, DsRadius.pill];

      // When
      final values = radii.toList();

      // Then
      expect(values, [4, 8, 16, 999]);
    });
  });

  for (final (name, theme) in [
    ('light', DsTheme.light()),
    ('dark', DsTheme.dark()),
  ]) {
    group('Given the $name theme with the standard brand', () {
      final colors = theme.extension<DsColors>()!;

      test('When each text role is measured on its background, '
          'Then every pair reaches at least 4.5:1', () {
        // Given
        final pairs = _textPairs(colors);

        // When
        final failing = {
          for (final MapEntry(key: pair, value: (fg, bg)) in pairs.entries)
            if (_contrast(fg, bg) < 4.5)
              pair: _contrast(fg, bg).toStringAsFixed(2),
        };

        // Then
        expect(failing, isEmpty);
      });

      test('When actionPrimary is measured against background, '
          'Then it reaches at least 3:1', () {
        // Given
        final action = colors.actionPrimary;

        // When
        final ratio = _contrast(action, colors.background);

        // Then
        expect(ratio, greaterThanOrEqualTo(3));
      });

      test('When the extensions are read, '
          'Then DsColors and DsTypography are both installed', () {
        // Given
        final data = theme;

        // When
        final typography = data.extension<DsTypography>();

        // Then
        expect(typography, isNotNull);
        expect(data.scaffoldBackgroundColor, colors.background);
        expect(data.colorScheme.primary, colors.actionPrimary);
      });
    });
  }

  group('Given brand colors that are too light or too dark', () {
    for (final primary in const [
      Color(0xFFFFEB3B), // pale yellow
      Color(0xFF0A0A40), // near-black navy
      Color(0xFF7F7F7F), // mid gray
    ]) {
      test('When both themes are built for $primary, '
          'Then every pair still reaches at least 4.5:1', () {
        // Given
        final brand = DsBrand(primary: primary);

        // When
        final failing = {
          for (final theme in [
            DsTheme.light(brand: brand),
            DsTheme.dark(brand: brand),
          ])
            for (final MapEntry(key: pair, value: (fg, bg)) in _textPairs(
              theme.extension<DsColors>()!,
            ).entries)
              if (_contrast(fg, bg) < 4.5)
                '${theme.brightness.name}: $pair': _contrast(
                  fg,
                  bg,
                ).toStringAsFixed(2),
        };

        // Then
        expect(failing, isEmpty);
      });
    }
  });

  group('Given two sets of color roles', () {
    test('When they are interpolated halfway, '
        'Then each role is halfway between the two', () {
      // Given
      final light = DsTheme.light().extension<DsColors>()!;
      final dark = DsTheme.dark().extension<DsColors>()!;

      // When
      final middle = light.lerp(dark, 0.5);

      // Then
      expect(
        middle.background,
        Color.lerp(light.background, dark.background, 0.5),
      );
      expect(light.lerp(null, 0.5), same(light));
    });

    test('When one role is copied with a new value, '
        'Then only that role changes', () {
      // Given
      final colors = DsTheme.light().extension<DsColors>()!;

      // When
      final copy = colors.copyWith(focus: const Color(0xFF00FF00));

      // Then
      expect(copy.focus, const Color(0xFF00FF00));
      expect(copy.actionPrimary, colors.actionPrimary);
    });
  });
}

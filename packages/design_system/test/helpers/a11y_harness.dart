import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test harness for the accessibility rules every component must meet
/// (contracts/design-system.md, D1–D4).
abstract final class DsA11yHarness {
  /// The two themes every component is checked under.
  static final List<(String, ThemeData)> themes = [
    ('light', DsTheme.light()),
    ('dark', DsTheme.dark()),
  ];

  /// Pumps [child] in an app with [theme], on the theme's background.
  ///
  /// [scrollable] wraps the child in a scroll view; turn it off for widgets
  /// that fill the screen, such as a page scaffold.
  static Future<void> pump(
    WidgetTester tester,
    Widget child, {
    required ThemeData theme,
    TextScaler textScaler = TextScaler.noScaling,
    bool scrollable = true,
  }) async {
    final content = Padding(
      padding: const EdgeInsets.all(DsSpacing.md),
      child: child,
    );
    await tester.pumpWidget(
      MaterialApp(
        // A new app per theme, so no theme animation or state carries over.
        key: ObjectKey(theme),
        theme: theme,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: app!,
        ),
        home: Scaffold(
          body: scrollable
              ? SingleChildScrollView(child: content)
              : SafeArea(child: content),
        ),
      ),
    );
    // Lets ink and focus animations finish without waiting on spinners.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Checks D1–D3 for [child] in the light and dark themes: tap targets of
  /// at least 48 × 48, a label on every tap target, and text contrast.
  static Future<void> expectMeetsGuidelines(
    WidgetTester tester,
    Widget child, {
    bool scrollable = true,
  }) async {
    final semantics = tester.ensureSemantics();
    for (final (name, theme) in themes) {
      await pump(tester, child, theme: theme, scrollable: scrollable);
      for (final guideline in [
        androidTapTargetGuideline,
        iOSTapTargetGuideline,
        labeledTapTargetGuideline,
        textContrastGuideline,
      ]) {
        await expectLater(
          tester,
          meetsGuideline(guideline),
          reason: '${guideline.description} ($name theme)',
        );
      }
    }
    semantics.dispose();
  }

  /// Checks D4 for [child]: at 200% text size on a 320-wide surface, in the
  /// light and dark themes, nothing overflows.
  static Future<void> expectNoOverflowAtLargeText(
    WidgetTester tester,
    Widget child, {
    bool scrollable = true,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(320, 800);
    addTearDown(tester.view.reset);
    for (final (_, theme) in themes) {
      await pump(
        tester,
        child,
        theme: theme,
        textScaler: const TextScaler.linear(2),
        scrollable: scrollable,
      );
      expect(tester.takeException(), isNull);
    }
  }

  /// Runs D1–D4 for each widget in [cases], one test per check and case.
  ///
  /// The keys name the cases, such as "disabled", in the test descriptions.
  static void describeRules(
    Map<String, Widget Function()> cases, {
    bool scrollable = true,
  }) {
    for (final MapEntry(key: name, value: build) in cases.entries) {
      testWidgets('When it is $name in either theme, '
          'Then it meets the tap-target, label, and contrast guidelines', (
        tester,
      ) async {
        // Given
        final widget = build();

        // When / Then
        await expectMeetsGuidelines(tester, widget, scrollable: scrollable);
      });

      testWidgets('When it is $name at 200% text on a 320-wide surface, '
          'Then nothing overflows', (tester) async {
        // Given
        final widget = build();

        // When / Then
        await expectNoOverflowAtLargeText(
          tester,
          widget,
          scrollable: scrollable,
        );
      });
    }
  }
}

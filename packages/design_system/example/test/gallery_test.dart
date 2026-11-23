// Feature: The gallery shows every component in every state, with light/dark
// and brand toggles (quickstart.md V6d).
import 'package:design_system/design_system.dart';
import 'package:design_system_gallery/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Given the gallery app', () {
    testWidgets('When it starts, Then every component type is shown', (
      tester,
    ) async {
      // Given
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(400, 6000);
      addTearDown(tester.view.reset);

      // When
      await tester.pumpWidget(const DesignSystemGalleryApp());
      await tester.pump();

      // Then
      for (final type in [
        DsButton,
        DsTextField,
        DsLoadingIndicator,
        DsCard,
        DsListTile,
        DsInlineMessage,
        DsEmptyState,
        DsPageScaffold,
      ]) {
        expect(find.byType(type), findsWidgets, reason: '$type');
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('When dark mode and another brand are chosen, '
        'Then the theme follows both', (tester) async {
      // Given
      await tester.pumpWidget(const DesignSystemGalleryApp());
      await tester.pump();

      // When
      await tester.tap(find.byType(Switch));
      await tester.tap(find.text('Forest'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Then
      final context = tester.element(find.byType(GalleryPage));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(
        context.dsColors.actionPrimary,
        DsTheme.dark(brand: const DsBrand(primary: Color(0xFF0B6E4F)))
            .extension<DsColors>()!
            .actionPrimary,
      );
    });
  });
}

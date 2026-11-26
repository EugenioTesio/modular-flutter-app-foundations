// Feature: Micro apps get the design system through their single Foundations
// dependency, by the original names (User Story 4; quickstart.md V6b).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';

void main() {
  group('Given only the Foundations import', () {
    testWidgets('When a page is built from design system components, '
        'Then it renders with the design system theme', (tester) async {
      // Given
      Color? background;
      final page = Builder(
        builder: (context) {
          background = context.dsColors.background;
          return DsPageScaffold(
            title: 'Sign in',
            body: Column(
              children: [
                const DsTextField(label: 'Email'),
                DsListTile(title: 'Forgot password?', onTap: () {}),
              ],
            ),
            primaryAction: DsButton(label: 'Sign in', onPressed: () {}),
          );
        },
      );

      // When
      await tester.pumpWidget(MaterialApp(theme: DsTheme.light(), home: page));

      // Then
      expect(find.text('Sign in'), findsNWidgets(2));
      expect(find.byType(DsTextField), findsOneWidget);
      expect(find.byType(DsListTile), findsOneWidget);
      expect(background, DsTheme.light().extension<DsColors>()!.background);
      expect(tester.takeException(), isNull);
    });
  });
}

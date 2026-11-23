// Feature: Micro apps keep state through one contract that runs on any
// adapter the host picks (User Story 4; quickstart.md V9; SC-013).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';
import 'package:switchable_state_bloc/switchable_state_bloc.dart';
import 'package:switchable_state_riverpod/switchable_state_riverpod.dart';

import '../support/sample_state_micro_app.dart';

Future<void> _pump(
  WidgetTester tester,
  StateAdapter adapter,
  Widget child, {
  List<StateOverride<Object>> overrides = const [],
}) async {
  await tester.pumpWidget(
    StateScope(
      adapter: adapter,
      overrides: overrides,
      child: MaterialApp(
        theme: DsTheme.light(),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Taps [label], then lets Cubit's stream deliver the change.
Future<void> _tap(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  group('Given the sample micro app source', () {
    test('When its imports are read, '
        'Then it uses only Flutter and Foundations', () {
      // Given
      final source = File('test/support/sample_state_micro_app.dart')
          .readAsStringSync();

      // When
      final packages = RegExp(
        r'''^import 'package:(\w+)/''',
        multiLine: true,
      ).allMatches(source).map((match) => match.group(1)).toSet();

      // Then
      expect(packages, {'flutter', 'foundations'});
    });
  });

  for (final (name, adapter) in <(String, StateAdapter)>[
    ('RiverpodStateAdapter', const RiverpodStateAdapter()),
    ('CubitStateAdapter', const CubitStateAdapter()),
  ]) {
    group('Given the sample micro app under $name', () {
      late SampleStateDeclarations state;

      setUp(() => state = SampleStateDeclarations());

      testWidgets('When app-wide state is changed from one widget, '
          'Then every widget that reads it shows the new value', (
        tester,
      ) async {
        // Given
        await _pump(
          tester,
          adapter,
          Column(
            children: [
              SampleDraftBadge(state: state, label: 'A '),
              SampleDraftBadge(state: state, label: 'B '),
            ],
          ),
        );

        // When
        await _tap(tester, 'A Add draft');
        await _tap(tester, 'A Add draft');

        // Then
        expect(find.text('A drafts: 2'), findsOneWidget);
        expect(find.text('B drafts: 2'), findsOneWidget);
      });

      testWidgets('When app-wide state outlives the widget that changed it, '
          'Then it keeps its value', (tester) async {
        // Given
        await _pump(tester, adapter, SampleDraftBadge(state: state));
        await _tap(tester, 'Add draft');

        // When
        await _pump(tester, adapter, const SizedBox());
        await _pump(tester, adapter, SampleDraftBadge(state: state));

        // Then
        expect(find.text('drafts: 1'), findsOneWidget);
      });

      testWidgets('When the user leaves and re-enters the group, '
          'Then the grouped state starts over', (tester) async {
        // Given
        await _pump(tester, adapter, SampleWizardGroup(state: state));
        await _tap(tester, 'Next');
        expect(find.text('step: review'), findsOneWidget);

        // When
        await _pump(tester, adapter, const SizedBox());
        await _pump(tester, adapter, SampleWizardGroup(state: state));

        // Then
        expect(find.text('step: amount'), findsOneWidget);
      });

      testWidgets('When a screen with its own store is closed and reopened, '
          'Then the store starts over', (tester) async {
        // Given
        await _pump(tester, adapter, const SampleAmountScreen());
        await _tap(tester, 'Increase');
        expect(find.text('amount: 1'), findsOneWidget);

        // When
        await _pump(tester, adapter, const SizedBox());
        await _pump(tester, adapter, const SampleAmountScreen());

        // Then
        expect(find.text('amount: 0'), findsOneWidget);
      });

      testWidgets('When initial values are overridden at the root and the '
          'group, Then the widgets start from them', (tester) async {
        // Given
        final overrides = [state.draftCount.overrideWith(() => 41)];

        // When
        await _pump(
          tester,
          adapter,
          Column(
            children: [
              SampleDraftBadge(state: state),
              SampleWizardGroup(
                state: state,
                overrides: [state.wizardStep.overrideWith(() => 'review')],
              ),
            ],
          ),
          overrides: overrides,
        );
        await _tap(tester, 'Add draft');

        // Then
        expect(find.text('drafts: 42'), findsOneWidget);
        expect(find.text('step: review'), findsOneWidget);
      });
    });
  }
}

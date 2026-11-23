// A sample micro app that keeps state only through the contract Foundations
// re-exports (quickstart.md V9). It imports nothing but Flutter and
// Foundations, and never names an adapter.
import 'package:flutter/material.dart';
import 'package:foundations/foundations.dart';

/// The sample micro app's state declarations.
final class SampleStateDeclarations {
  /// App-wide: owned by the root scope, kept for the app's lifetime.
  final AppState<int> draftCount = AppState<int>(
    () => 0,
    debugName: 'transfers.draftCount',
  );

  /// Grouped: owned by the wizard's [StateScope.group], closed when the user
  /// leaves the wizard.
  final AppState<String> wizardStep = AppState<String>.grouped(
    () => 'amount',
    debugName: 'transfers.wizardStep',
  );
}

/// Shows and changes the app-wide draft count.
final class SampleDraftBadge extends StatelessWidget {
  const SampleDraftBadge({super.key, required this.state, this.label = ''});

  final SampleStateDeclarations state;
  final String label;

  @override
  Widget build(BuildContext context) {
    final drafts = StateScope.of(context).store(state.draftCount);
    return Column(
      children: [
        drafts.watch((count) => Text('${label}drafts: $count')),
        DsButton(
          label: '${label}Add draft',
          onPressed: () => drafts.update((count) => count + 1),
        ),
      ],
    );
  }
}

/// The wizard's route group: owns the grouped wizard step.
final class SampleWizardGroup extends StatelessWidget {
  const SampleWizardGroup({
    super.key,
    required this.state,
    this.overrides = const [],
  });

  final SampleStateDeclarations state;
  final List<StateOverride<Object>> overrides;

  @override
  Widget build(BuildContext context) {
    return StateScope.group(
      owns: [state.wizardStep],
      overrides: overrides,
      child: _SampleWizardStep(state: state),
    );
  }
}

final class _SampleWizardStep extends StatelessWidget {
  const _SampleWizardStep({required this.state});

  final SampleStateDeclarations state;

  @override
  Widget build(BuildContext context) {
    final step = StateScope.of(context).store(state.wizardStep);
    return Column(
      children: [
        step.watch((value) => Text('step: $value')),
        DsButton(label: 'Next', onPressed: () => step.replace('review')),
      ],
    );
  }
}

/// A screen whose amount store is owned by the screen itself.
final class SampleAmountScreen extends StatefulWidget {
  const SampleAmountScreen({super.key});

  @override
  State<SampleAmountScreen> createState() => _SampleAmountScreenState();
}

final class _SampleAmountScreenState extends State<SampleAmountScreen>
    with StateStoreOwner<SampleAmountScreen> {
  late final StateStore<int> _amount;

  @override
  void initState() {
    super.initState();
    _amount = createStore(0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _amount.watch((value) => Text('amount: $value')),
        DsButton(
          label: 'Increase',
          onPressed: () => _amount.update((value) => value + 1),
        ),
      ],
    );
  }
}

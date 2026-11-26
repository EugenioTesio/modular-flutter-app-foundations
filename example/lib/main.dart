import 'package:flutter/material.dart';
import 'package:foundations/foundations.dart';
import 'package:switchable_state_riverpod/switchable_state_riverpod.dart';

import 'cards.dart';
import 'home.dart';
import 'host/example_host.dart';
import 'host/example_services.dart';
import 'transfers.dart';

/// Starts the example the way a host does: the root [StateScope] sits above
/// the app, and this is the one line that picks the state library.
void main() => runApp(
  StateScope(
    adapter: const RiverpodStateAdapter(),
    child: const FoundationsExampleApp(),
  ),
);

/// Example app for the Foundations contracts.
///
/// It plays the host: it lists the micro apps, starts them through
/// [ExampleHost] (one [MicroAppContext] each), applies the design system's
/// themes, and opens Home. The "Cards installed" switch restarts the host
/// with or without Cards, like a build with or without that micro app.
class FoundationsExampleApp extends StatefulWidget {
  /// Creates the app with Cards installed.
  const FoundationsExampleApp({super.key});

  /// The backend answers the example serves.
  static const defaultApiResponses = <String, Object?>{
    CardsMicroApp.primaryCardPath: {
      'maskedNumber': '•••• 4821',
      'availableCredit': '2,500',
    },
  };

  @override
  State<FoundationsExampleApp> createState() => _FoundationsExampleAppState();
}

class _FoundationsExampleAppState extends State<FoundationsExampleApp> {
  final _session = ExampleSessionContext(DemoSessions.signedIn);
  var _cardsInstalled = true;
  ExampleHost? _host;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  /// Starts a host with the micro apps of this build. Registrations can't be
  /// removed, so a different set of micro apps means a new host.
  Future<void> _restart() async {
    final previous = _host;
    final host = ExampleHost(
      session: _session,
      apiResponses: FoundationsExampleApp.defaultApiResponses,
      initialLocation: '/home',
      microApps: [
        HomeMicroApp(),
        TransfersMicroApp(prepareScenario: _session.set),
        if (_cardsInstalled) CardsMicroApp(),
      ],
    );
    await host.start();
    if (!mounted) {
      await host.dispose();
      return;
    }
    setState(() => _host = host);
    // The previous router stays in use until the new app replaces it.
    await WidgetsBinding.instance.endOfFrame;
    await previous?.dispose();
  }

  @override
  void dispose() {
    _host?.dispose();
    _session.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final host = _host;
    if (host == null) {
      return MaterialApp(
        theme: DsTheme.light(),
        darkTheme: DsTheme.dark(),
        home: const Scaffold(
          body: Center(child: DsLoadingIndicator(semanticsLabel: 'Starting')),
        ),
      );
    }
    return MaterialApp.router(
      // A new router for each host.
      key: ObjectKey(host),
      title: 'Foundations example',
      theme: DsTheme.light(),
      darkTheme: DsTheme.dark(),
      localizationsDelegates: host.localizationsDelegates,
      routerConfig: host.navigator.router,
      builder: (context, child) => Column(
        children: [
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: child!,
            ),
          ),
          Material(
            color: context.dsColors.surface,
            child: SafeArea(
              top: false,
              child: SwitchListTile(
                title: Text(
                  'Cards installed',
                  style: TextStyle(color: context.dsColors.textPrimary),
                ),
                value: _cardsInstalled,
                onChanged: (value) {
                  setState(() => _cardsInstalled = value);
                  _restart();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

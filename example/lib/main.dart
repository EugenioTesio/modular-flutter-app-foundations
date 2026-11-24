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
    child: FoundationsExampleApp.create(),
  ),
);

/// Example app for the Foundations contracts.
///
/// It plays the host: it lists the micro apps, starts them through
/// [ExampleHost] (one [MicroAppContext] each), applies the design system's
/// themes, and opens Home. The "Cards installed" switch restarts the host
/// with or without Cards, like a build with or without that micro app.
class FoundationsExampleApp extends StatefulWidget {
  /// Creates the app.
  ///
  /// [cardsInstalled] sets whether the app starts with the Cards micro app.
  /// [apiResponses] are the canned backend answers; they default to
  /// [defaultApiResponses].
  const FoundationsExampleApp({
    super.key,
    this.cardsInstalled = true,
    this.apiResponses = defaultApiResponses,
  });

  /// Creates the app the way `main` does.
  factory FoundationsExampleApp.create({bool cardsInstalled = true}) =>
      FoundationsExampleApp(cardsInstalled: cardsInstalled);

  /// The backend answers the example serves.
  static const defaultApiResponses = <String, Object?>{
    CardsMicroApp.primaryCardPath: {
      'maskedNumber': '•••• 4821',
      'availableCredit': '2,500',
    },
  };

  /// Whether the app starts with the Cards micro app installed.
  final bool cardsInstalled;

  /// The canned backend answers.
  final Map<String, Object?> apiResponses;

  @override
  State<FoundationsExampleApp> createState() => _FoundationsExampleAppState();
}

class _FoundationsExampleAppState extends State<FoundationsExampleApp> {
  final _session = ExampleSessionContext(DemoSessions.signedIn);
  late var _cardsInstalled = widget.cardsInstalled;
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
      apiResponses: widget.apiResponses,
      microApps: [
        HomeMicroApp(),
        TransfersMicroApp(prepareScenario: _session.set),
        if (_cardsInstalled) CardsMicroApp(),
      ],
    );
    await host.start();
    await previous?.dispose();
    if (mounted) setState(() => _host = host);
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
    final navigator = host.navigator;
    return MaterialApp(
      // A new navigator for each host.
      key: ObjectKey(host),
      title: 'Foundations example',
      theme: DsTheme.light(),
      darkTheme: DsTheme.dark(),
      localizationsDelegates: host.localizationsDelegates,
      navigatorKey: navigator.navigatorKey,
      navigatorObservers: [navigator.observer],
      onGenerateRoute: navigator.onGenerateRoute,
      onGenerateInitialRoutes: (_) => [
        navigator.onGenerateRoute(const RouteSettings(name: '/home'))!,
      ],
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

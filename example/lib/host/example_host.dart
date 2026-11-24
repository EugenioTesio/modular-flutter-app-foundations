import 'package:flutter/widgets.dart';
import 'package:foundations/foundations.dart';

import 'example_inter_module_communication.dart';
import 'example_navigator.dart';
import 'example_services.dart';

/// The example's host: it integrates any list of micro apps the same way
/// Core does, through [MicroApp] and [MicroAppContext] only.
///
/// [start] runs the host sequence:
/// 1. Checks that ids and declared stored keys are unique.
/// 2. Builds one [MicroAppContext] per micro app. The shared services are the
///    same instances for everyone; the stores are limited to each micro
///    app's own keys.
/// 3. Initializes the micro apps, in list order.
/// 4. Checks and installs every declared route in the navigator. A broken
///    or duplicate path stops startup.
/// 5. Registers every declared endpoint provider in one step.
///
/// The navigator sends a signed-out user to sign-in for routes that require
/// it. [dispose] disposes the micro apps in reverse order, and keeps going
/// when one fails.
final class ExampleHost {
  /// Creates a host for [microApps].
  ///
  /// [session] is shared with the caller, so the demo can change it;
  /// [apiResponses] are the canned backend answers; [initialLocation] is
  /// the location the router opens first, and defaults to `/`.
  ExampleHost({
    required this.microApps,
    required this.session,
    Map<String, Object?> apiResponses = const {},
    this.initialLocation = '/',
  }) : apiClient = ExampleApiClient(responses: apiResponses),
       navigator = ExampleNavigator(session: session);

  /// The micro apps, in initialization order.
  final List<MicroApp> microApps;

  /// The location the router opens first.
  final String initialLocation;

  /// The signed-in user, shared by every micro app.
  final ExampleSessionContext session;

  /// The backend client, shared by every micro app.
  final ApiClient apiClient;

  /// Inter-module communication, shared by every micro app.
  final InterModuleCommunication communication =
      ExampleInterModuleCommunication();

  /// Navigation over go_router, shared by every micro app. Its redirect
  /// guards routes that require sign-in with [session].
  final ExampleNavigator navigator;

  final _storage = <String, String>{};
  final _secureStorage = <String, String>{};

  /// Every micro app's localization delegates, after [start].
  List<LocalizationsDelegate<Object?>> get localizationsDelegates => [
    for (final app in microApps) ...app.localizationsDelegates,
  ];

  /// Runs the host sequence. Throws a [StateError] naming the culprits when
  /// two micro apps share an id or a stored key, or when a route path breaks
  /// a rule, and lets a [DuplicateEndpointException] propagate.
  Future<void> start() async {
    _checkUnique('id', {
      for (final app in microApps) app: {app.id},
    });
    _checkUnique('stored key', {
      for (final app in microApps) app: app.storedKeys,
    });

    for (final app in microApps) {
      await app.initialize(_contextFor(app));
    }

    navigator.install({
      for (final app in microApps) app.id: app.routes,
    }, initialLocation: initialLocation);
    communication.registerProviders(
      data: [for (final app in microApps) ...app.dataEndpoints],
      widgets: [for (final app in microApps) ...app.widgetEndpoints],
    );
  }

  /// Disposes the micro apps in reverse order, then the router.
  ///
  /// A failure is logged and returned with the micro app's id, and the
  /// remaining micro apps are still disposed.
  Future<List<(String, Object)>> dispose() async {
    final failures = <(String, Object)>[];
    for (final app in microApps.reversed) {
      try {
        await app.dispose();
      } on Object catch (error, stackTrace) {
        failures.add((app.id, error));
        const ExampleAppLogger().error(
          'Micro app failed to dispose',
          error: error,
          stackTrace: stackTrace,
          context: {'microAppId': app.id},
        );
      }
    }
    navigator.dispose();
    return failures;
  }

  MicroAppContext _contextFor(MicroApp app) => MicroAppContext(
    communication: communication,
    apiClient: apiClient,
    analytics: const ExampleAnalytics(),
    crashReporter: const ExampleCrashReporter(),
    logger: const ExampleAppLogger(),
    featureFlags: const ExampleFeatureFlags(),
    keyValueStore: ExampleKeyValueStore(
      declaredKeys: app.storedKeys,
      entries: _storage,
    ),
    secureKeyValueStore: ExampleSecureKeyValueStore(
      declaredKeys: app.storedKeys,
      entries: _secureStorage,
    ),
    navigator: navigator,
    session: session,
    devicePermissions: const ExampleDevicePermissions(),
    appInfo: const ExampleAppInfo(),
  );

  static void _checkUnique(String what, Map<MicroApp, Set<String>> values) {
    final owners = <String, List<String>>{};
    values.forEach((app, keys) {
      for (final key in keys) {
        (owners[key] ??= []).add(app.id);
      }
    });
    final clashes = owners.entries.where((entry) => entry.value.length > 1);
    if (clashes.isNotEmpty) {
      throw StateError(
        'Duplicate $what: ${clashes.map((e) => '"${e.key}" in ${e.value}').join(', ')}',
      );
    }
  }
}

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
/// 4. Registers every declared endpoint provider in one step.
/// 5. Installs every declared route in the navigator.
///
/// [dispose] disposes the micro apps in reverse order.
final class ExampleHost {
  /// Creates a host for [microApps].
  ///
  /// [session] is shared with the caller, so the demo can change it;
  /// [apiResponses] are the canned backend answers.
  ExampleHost({
    required this.microApps,
    required this.session,
    Map<String, Object?> apiResponses = const {},
  }) : apiClient = ExampleApiClient(responses: apiResponses);

  /// The micro apps, in initialization order.
  final List<MicroApp> microApps;

  /// The signed-in user, shared by every micro app.
  final ExampleSessionContext session;

  /// The backend client, shared by every micro app.
  final ApiClient apiClient;

  /// Inter-module communication, shared by every micro app.
  final InterModuleCommunication communication =
      ExampleInterModuleCommunication();

  /// Navigation, shared by every micro app.
  final navigator = ExampleNavigator();

  final _storage = <String, String>{};
  final _secureStorage = <String, String>{};

  /// Every micro app's localization delegates, after [start].
  List<LocalizationsDelegate<Object?>> get localizationsDelegates => [
    for (final app in microApps) ...app.localizationsDelegates,
  ];

  /// Runs the host sequence. Throws a [StateError] naming the culprits when
  /// two micro apps share an id or a stored key, and lets a
  /// [DuplicateEndpointException] propagate.
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

    communication.registerProviders(
      data: [for (final app in microApps) ...app.dataEndpoints],
      widgets: [for (final app in microApps) ...app.widgetEndpoints],
    );
    navigator.install([for (final app in microApps) ...app.routes]);
  }

  /// Disposes the micro apps in reverse order.
  Future<void> dispose() async {
    for (final app in microApps.reversed) {
      await app.dispose();
    }
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

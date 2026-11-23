// Reference implementation of the host sequence in contracts/micro-app.md,
// steps 1–7. Dev-only: it knows nothing but MicroApp, so any micro app plugs
// in without host code specific to it. Core's reusable host implementation
// (the counterpart of AppShellContainer) follows the same steps.
import 'package:flutter/widgets.dart';
import 'package:foundations/foundations.dart';

import 'fakes.dart';
import 'reference_inter_module_communication.dart';
import 'reference_route_validation.dart';
import 'reference_router.dart';
import 'reference_startup_exception.dart';

/// The contracts every micro app shares. Storage and navigation are not here:
/// the host builds storage per micro app and owns the navigator.
final class ReferenceHostServices {
  /// Creates the shared services.
  const ReferenceHostServices({
    required this.communication,
    required this.apiClient,
    required this.analytics,
    required this.crashReporter,
    required this.logger,
    required this.featureFlags,
    required this.session,
    required this.devicePermissions,
    required this.appInfo,
  });

  /// Creates services backed by the in-memory fakes, with a reference
  /// communication implementation unless [communication] is given.
  factory ReferenceHostServices.fakes({
    SessionContext? session,
    InterModuleCommunication? communication,
    AppLogger? logger,
    ApiClient? apiClient,
  }) => ReferenceHostServices(
    communication: communication ?? ReferenceInterModuleCommunication(),
    apiClient: apiClient ?? RecordingApiClient(),
    analytics: const NoOpAnalytics(),
    crashReporter: const NoOpCrashReporter(),
    logger: logger ?? const NoOpAppLogger(),
    featureFlags: InMemoryFeatureFlags(),
    session: session ?? FakeSessionContext(),
    devicePermissions: FakeDevicePermissions(),
    appInfo: const FakeAppInfo(),
  );

  /// Inter-module communication.
  final InterModuleCommunication communication;

  /// The backend client.
  final ApiClient apiClient;

  /// Product analytics.
  final Analytics analytics;

  /// Crash reporting.
  final CrashReporter crashReporter;

  /// Diagnostic logging; teardown failures are reported here.
  final AppLogger logger;

  /// Feature flags.
  final FeatureFlags featureFlags;

  /// The session, which also drives sign-in redirects.
  final SessionContext session;

  /// Device permissions.
  final DevicePermissions devicePermissions;

  /// Application facts.
  final AppInfo appInfo;
}

/// A navigator that exists before the router does.
///
/// Contexts are built (step 2) before routes can be read (step 4), so the
/// host hands out this navigator and points it at the router in step 6.
final class ReferenceNavigatorSlot implements AppNavigator {
  /// The navigator calls are forwarded to, once the router exists.
  AppNavigator? target;

  AppNavigator get _target =>
      target ?? (throw StateError('Navigation used before the router exists.'));

  @override
  Future<Result<NavigationResult, NavigationException>> push(
    String path, {
    Map<String, Object> body = const {},
  }) => _target.push(path, body: body);

  @override
  Result<void, NavigationException> go(
    String path, {
    Map<String, Object> body = const {},
  }) => _target.go(path, body: body);

  @override
  Future<Result<NavigationResult, NavigationException>> replace(
    String path, {
    Map<String, Object> body = const {},
  }) => _target.replace(path, body: body);

  @override
  void pop({Map<String, Object>? result}) => _target.pop(result: result);

  @override
  Result<void, NavigationException> popUntil(String path) =>
      _target.popUntil(path);
}

/// Runs the host sequence over [microApps], in list order.
final class ReferenceHost {
  /// Creates a host.
  ///
  /// [storage] and [secureStorage] model the device's two stores, shared by
  /// every micro app's limited view of them. The router starts at
  /// [initialLocation] and sends unsigned users to [signInPath].
  ReferenceHost({
    required this.microApps,
    required this.services,
    this.signInPath = '/auth/sign-in',
    this.initialLocation = '/home',
    Map<String, String>? storage,
    Map<String, String>? secureStorage,
  }) : storage = storage ?? {},
       secureStorage = secureStorage ?? {};

  /// The micro apps, in initialization order.
  final List<MicroApp> microApps;

  /// The shared contracts.
  final ReferenceHostServices services;

  /// Where routes that require sign-in redirect.
  final String signInPath;

  /// The router's first location.
  final String initialLocation;

  /// The device's general storage.
  final Map<String, String> storage;

  /// The device's secure storage.
  final Map<String, String> secureStorage;

  /// The navigator every context receives.
  final ReferenceNavigatorSlot navigator = ReferenceNavigatorSlot();

  /// Each micro app's context, by id. Filled in step 2.
  final Map<String, MicroAppContext> contexts = {};

  /// Every validated route. Filled in step 4.
  final List<ReferenceRouteEntry> routes = [];

  /// Every localization delegate. Filled in step 4.
  final List<LocalizationsDelegate<Object?>> localizationsDelegates = [];

  /// The router. Built in step 6.
  ReferenceRouter? router;

  final List<MicroApp> _initialized = [];

  /// Runs steps 1–6.
  ///
  /// Throws a [ReferenceStartupException] for a duplicate id, stored key, or
  /// route path, and lets a [DuplicateEndpointException] through.
  Future<void> start() async {
    // 1. Read ids and stored keys; duplicates stop startup.
    final ids = <String>{};
    final keyOwners = <String, String>{};
    for (final microApp in microApps) {
      if (!ids.add(microApp.id)) {
        throw ReferenceStartupException(
          'Duplicate micro app id "${microApp.id}".',
        );
      }
      for (final key in microApp.storedKeys) {
        final owner = keyOwners[key];
        if (owner != null) {
          throw ReferenceStartupException(
            'Stored key "$key" is declared by both "$owner" and '
            '"${microApp.id}".',
          );
        }
        keyOwners[key] = microApp.id;
      }
    }

    // 2. One context per micro app, with storage limited to its keys.
    for (final microApp in microApps) {
      contexts[microApp.id] = MicroAppContext(
        communication: services.communication,
        apiClient: services.apiClient,
        analytics: services.analytics,
        crashReporter: services.crashReporter,
        logger: services.logger,
        featureFlags: services.featureFlags,
        keyValueStore: InMemoryKeyValueStore(
          declaredKeys: microApp.storedKeys,
          entries: storage,
        ),
        secureKeyValueStore: InMemorySecureKeyValueStore(
          declaredKeys: microApp.storedKeys,
          entries: secureStorage,
        ),
        navigator: navigator,
        session: services.session,
        devicePermissions: services.devicePermissions,
        appInfo: services.appInfo,
      );
    }

    // 3. Initialize, in order.
    for (final microApp in microApps) {
      await microApp.initialize(contexts[microApp.id]!);
      _initialized.add(microApp);
    }

    // 4. Collect declarations; check full paths.
    final routesByMicroApp = {
      for (final microApp in microApps) microApp.id: microApp.routes,
    };
    routes.addAll(ReferenceRouteValidation.validate(routesByMicroApp));
    for (final microApp in microApps) {
      localizationsDelegates.addAll(microApp.localizationsDelegates);
    }

    // 5. Register every provider at once; a duplicate URL throws.
    services.communication.registerProviders(
      data: [for (final microApp in microApps) ...microApp.dataEndpoints],
      widgets: [for (final microApp in microApps) ...microApp.widgetEndpoints],
    );

    // 6. Build the router and point the shared navigator at it. A real host
    // then wraps MaterialApp.router in the root StateScope and runs.
    final built = ReferenceRouter(
      routes: [for (final list in routesByMicroApp.values) ...list],
      session: services.session,
      signInPath: signInPath,
      initialLocation: initialLocation,
    );
    router = built;
    navigator.target = built;
  }

  /// Runs step 7: disposes the initialized micro apps in reverse order.
  ///
  /// A failure is logged as an error and returned, and the remaining micro
  /// apps are still disposed. Calling it again does nothing.
  Future<List<(String, Object)>> dispose() async {
    final failures = <(String, Object)>[];
    for (final microApp in _initialized.reversed) {
      try {
        await microApp.dispose();
      } on Object catch (error, stackTrace) {
        failures.add((microApp.id, error));
        services.logger.error(
          'Micro app failed to dispose',
          error: error,
          stackTrace: stackTrace,
          context: {'microAppId': microApp.id},
        );
      }
    }
    _initialized.clear();
    // Teardown may run twice (for example a test and its tearDown).
    final built = router;
    router = null;
    navigator.target = null;
    await built?.dispose();
    return failures;
  }
}

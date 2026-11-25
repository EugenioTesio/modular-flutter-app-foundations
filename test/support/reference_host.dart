// Reference host for the host sequence in contracts/micro-app.md, steps 1–7.
// Dev-only: it knows nothing but MicroApp, so any micro app plugs in without
// host code specific to it. ModularAppContainer runs steps 1–5 and 7; this
// host adds the fakes for the contexts and the router (step 6).
import 'package:flutter/widgets.dart';
import 'package:foundations/foundations.dart';

import 'fakes.dart';
import 'reference_inter_module_communication.dart';
import 'reference_router.dart';

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
    CrashReporter? crashReporter,
  }) => ReferenceHostServices(
    communication: communication ?? ReferenceInterModuleCommunication(),
    apiClient: apiClient ?? RecordingApiClient(),
    analytics: const NoOpAnalytics(),
    crashReporter: crashReporter ?? const NoOpCrashReporter(),
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

/// Runs the host sequence over its micro apps, in list order, through a
/// [ModularAppContainer].
final class ReferenceHost {
  /// Creates a host.
  ///
  /// [storage] and [secureStorage] model the device's two stores, shared by
  /// every micro app's limited view of them. The router starts at
  /// [initialLocation] and sends unsigned users to [signInPath].
  ReferenceHost({
    required List<MicroApp> microApps,
    required this.services,
    this.signInPath = '/auth/sign-in',
    this.initialLocation = '/home',
    Map<String, String>? storage,
    Map<String, String>? secureStorage,
  }) : container = ModularAppContainer(microApps: microApps),
       storage = storage ?? {},
       secureStorage = secureStorage ?? {};

  /// The container that starts the micro apps and gathers their
  /// declarations.
  final ModularAppContainer container;

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

  /// Every localization delegate, after [start].
  List<LocalizationsDelegate<Object?>> get localizationsDelegates =>
      container.localizationsDelegates;

  /// The router. Built in step 6.
  ReferenceRouter? router;

  /// Runs steps 1–6.
  ///
  /// Throws a [ModularAppStartupException] for a duplicate id, stored key,
  /// or route path, and lets a [DuplicateEndpointException] through.
  Future<void> start() async {
    // Steps 1–5: the container.
    await container.bootstrap(
      communication: services.communication,
      contextFor: _contextFor,
    );

    // 6. Build the router and point the shared navigator at it. A real host
    // then wraps MaterialApp.router in the root StateScope and runs.
    final built = ReferenceRouter(
      routes: container.routes,
      requiresAuthentication: container.requiresAuthentication,
      session: services.session,
      signInPath: signInPath,
      initialLocation: initialLocation,
    );
    router = built;
    navigator.target = built;
  }

  /// Runs step 7: disposes the initialized micro apps in reverse order, then
  /// the router.
  ///
  /// A failure is logged as an error and returned, and the remaining micro
  /// apps are still disposed. Calling it again does nothing.
  Future<List<(String, Object)>> dispose() async {
    final failures = await container.dispose();
    // Teardown may run twice (for example a test and its tearDown).
    final built = router;
    router = null;
    navigator.target = null;
    await built?.dispose();
    return failures;
  }

  // Step 2: one context per micro app, with storage limited to its keys.
  MicroAppContext _contextFor(MicroApp microApp) => MicroAppContext(
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

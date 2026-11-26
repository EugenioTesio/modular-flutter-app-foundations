import 'package:flutter/widgets.dart';
import 'package:foundations/foundations.dart';

import 'example_inter_module_communication.dart';
import 'example_navigator.dart';
import 'example_services.dart';

/// The example's host: it integrates any list of micro apps the same way
/// Core does, through [MicroApp] and [MicroAppContext] only.
///
/// [start] runs the host sequence through a [ModularAppContainer], which:
/// 1. Checks that ids and declared stored keys are unique.
/// 2. Builds one [MicroAppContext] per micro app. The
///    shared services are the same instances for everyone; the stores are
///    limited to each micro app's own keys.
/// 3. Initializes the micro apps, in list order.
/// 4. Checks every declared route, the host's sign-in route included,
///    keeping the trees as declared. A broken or duplicate path, or a host
///    route inside a micro app's paths, stops startup.
/// 5. Registers every declared endpoint provider in one step.
///
/// The host then installs every route, its own first, in the navigator,
/// which sends a signed-out user to sign-in for routes that require it. [dispose]
/// disposes the micro apps in reverse order, and keeps going when one fails.
final class ExampleHost {
  /// Creates a host for [microApps].
  ///
  /// [session] is shared with the caller, so the demo can change it;
  /// [apiResponses] are the canned backend answers; [initialLocation] is
  /// the location the router opens first, and defaults to `/`.
  ExampleHost({
    required List<MicroApp> microApps,
    required this.session,
    Map<String, Object?> apiResponses = const {},
    this.initialLocation = '/',
  }) : container = ModularAppContainer(
         microApps: microApps,
         host: ModularAppHost(
           routes: [
             MicroAppRoute(
               path: ExampleNavigator.signInPath,
               builder: (context, parameters, body) =>
                   const ExampleSignInRequiredScreen(),
               requiresAuthentication: false,
             ),
           ],
         ),
       ),
       apiClient = ExampleApiClient(responses: apiResponses),
       navigator = ExampleNavigator(session: session);

  /// The container that starts the micro apps and gathers their
  /// declarations.
  final ModularAppContainer container;

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
  List<LocalizationsDelegate<Object?>> get localizationsDelegates =>
      container.localizationsDelegates;

  /// Runs the host sequence.
  ///
  /// Throws a [ModularAppStartupException] naming the culprits when two
  /// micro apps share an id or a stored key, or when a route path breaks a
  /// rule, and lets a [DuplicateEndpointException] propagate.
  Future<void> start() async {
    await container.bootstrap(
      communication: communication,
      contextFor: _contextFor,
    );
    navigator.install(
      routes: container.routes,
      requiresAuthentication: container.requiresAuthentication,
      initialLocation: initialLocation,
    );
  }

  /// Disposes the micro apps in reverse order, then the router.
  ///
  /// A failure is logged and returned with the micro app's id, and the
  /// remaining micro apps are still disposed.
  Future<List<(String, Object)>> dispose() async {
    final failures = await container.dispose();
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
}

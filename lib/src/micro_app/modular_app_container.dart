/// @docImport '../exceptions/duplicate_endpoint_exception.dart';
library;

import 'package:flutter/widgets.dart';

import '../capabilities/app_logger.dart';
import '../exceptions/modular_app_startup_exception.dart';
import '../inter_module/endpoint_provider.dart';
import '../inter_module/inter_module_communication.dart';
import '../inter_module/inter_module_endpoint.dart';
import '../routing/micro_app_route.dart';
import 'micro_app.dart';
import 'micro_app_context.dart';
import 'modular_app_host.dart';
import 'modular_app_route_checks.dart';

/// Function that builds the [MicroAppContext] one micro app receives.
///
/// Use this to give [ModularAppContainer.bootstrap] the host's contracts:
/// most services are the same instances for every micro app, while the crash
/// reporter adds the micro app's [MicroApp.id] to its reports and the stores
/// are limited to the micro app's own [MicroApp.storedKeys].
///
/// Usage from a host:
/// ```dart
/// MicroAppContext contextFor(MicroApp microApp) => MicroAppContext(
///   communication: communication,
///   apiClient: apiClient,
///   crashReporter: ScopedCrashReporter(microApp.id, crashVendor),
///   // ... the other shared services ...
///   keyValueStore: ScopedKeyValueStore(microApp.storedKeys, preferences),
///   secureKeyValueStore: ScopedSecureStore(microApp.storedKeys, keychain),
/// );
/// ```
typedef MicroAppContextFactory = MicroAppContext Function(MicroApp microApp);

/// Container that starts a host's micro apps and gathers what the
/// application needs from them.
///
/// Use this in the App Shell, a standalone example, or any other host to run
/// the host sequence once, instead of writing it again: it checks the micro
/// apps' and the [host]'s declarations, gives each micro app its own
/// [MicroAppContext], initializes them, registers every endpoint, and hands
/// the router and the localizations exactly what was declared.
///
/// This is **not** a router or a service locator: it builds no router and
/// holds no global instance. The host builds the router from [routes], which
/// include its own [ModularAppHost.routes], guards it with
/// [requiresAuthentication], and passes [localizationsDelegates] to its
/// `MaterialApp`.
///
/// Built-in: [bootstrap] runs, in order:
/// 1. Checks that micro app ids are unique, and that no stored key is
///    declared twice, by two micro apps or by the [host] and a micro app. A
///    duplicate throws a [ModularAppStartupException] before any micro app
///    initializes.
/// 2. Builds one context per micro app with the host's
///    [MicroAppContextFactory].
/// 3. Calls [MicroApp.initialize] on each micro app, in [microApps] order.
/// 4. Reads each micro app's routes and localization delegates, and checks
///    the micro apps' and the [host]'s route trees without changing them.
/// 5. Registers the [host]'s and every micro app's endpoint providers in one
///    [InterModuleProviderRegistration.registerProviders] call.
///
/// [dispose] then releases the micro apps in reverse order.
///
/// Rules:
/// * A container starts once. Build a new one for a different set of micro
///   apps.
/// * Route trees and delegates are handed over as declared: no tree is
///   flattened, merged, or re-rooted.
/// * To the logs and crash reports it writes, the container adds the micro app
///   id and timings only, never payloads, credentials, or personal data. An
///   error and its stack trace are forwarded as thrown, so the host's
///   implementations strip any input the error quotes.
///
/// Usage from a host:
/// ```dart
/// final container = ModularAppContainer(
///   microApps: [HomeMicroApp(), AccountsMicroApp(), TransfersMicroApp()],
///   host: ModularAppHost(
///     routes: [
///       MicroAppRoute(
///         path: '/sign-in',
///         builder: (context, parameters, body) => const SignInScreen(),
///         requiresAuthentication: false,
///       ),
///     ],
///     localizationsDelegates: [AppLocalizations.delegate],
///   ),
/// );
/// await container.bootstrap(
///   communication: communication,
///   contextFor: contextFor,
/// );
///
/// final router = GoRouter(
///   routes: [...container.routes.map(toGoRoute)],
///   redirect: (context, state) =>
///       container.requiresAuthentication(state.fullPath ?? '') == true &&
///               session.current is Unauthenticated
///           ? '/sign-in'
///           : null,
/// );
/// runApp(MaterialApp.router(
///   routerConfig: router,
///   localizationsDelegates: [
///     ...container.localizationsDelegates,
///     GlobalMaterialLocalizations.delegate,
///   ],
/// ));
/// ```
final class ModularAppContainer {
  /// Creates a container for [microApps] and the [host]'s own
  /// declarations.
  ///
  /// Parameters:
  /// * [microApps] - The micro apps, in initialization order. The list is
  ///   copied, so later changes to it have no effect.
  /// * [host] - The host's own routes, localization delegates, stored keys,
  ///   and endpoints; defaults to none of them.
  ModularAppContainer({
    required List<MicroApp> microApps,
    this.host = const ModularAppHost(),
  }) : microApps = List.unmodifiable(microApps);

  /// Micro apps, in initialization order.
  final List<MicroApp> microApps;

  /// Host's own declarations, gathered first and checked with the micro
  /// apps'.
  final ModularAppHost host;

  /// Micro apps whose [MicroApp.initialize] completed, in order.
  final List<MicroApp> _initialized = [];
  Map<String, MicroAppContext> _contexts = const {};
  _ModularAppDeclarations? _declarations;
  bool _started = false;
  bool _disposed = false;

  /// Whether [bootstrap] has completed and [dispose] hasn't run since.
  bool get isInitialized => _declarations != null && !_disposed;

  /// Every top-level route node: the [host]'s first, then each micro app's,
  /// in [microApps] order.
  ///
  /// The nodes are the declared objects, one list after another, so each
  /// tree keeps the nesting, groups, and sign-in flags its owner declared.
  /// Pass them to the router as its whole route list.
  ///
  /// Throws a [StateError] before [bootstrap] completes.
  List<MicroAppRouteNode> get routes => _gathered.routes;

  /// Each micro app's route tree as declared, keyed by micro app id, in
  /// [microApps] order. The [host]'s routes are not included.
  ///
  /// Throws a [StateError] before [bootstrap] completes.
  Map<String, List<MicroAppRouteNode>> get routesByMicroApp =>
      _gathered.routesByMicroApp;

  /// Every localization delegate: the [host]'s first, then each micro
  /// app's, in [microApps] order.
  ///
  /// Pass them to `MaterialApp.localizationsDelegates`, with Flutter's own
  /// delegates, such as `GlobalMaterialLocalizations.delegate`.
  ///
  /// Throws a [StateError] before [bootstrap] completes.
  List<LocalizationsDelegate<Object?>> get localizationsDelegates =>
      _gathered.localizationsDelegates;

  /// Each micro app's localization delegates as declared, keyed by micro
  /// app id, in [microApps] order. The [host]'s are not included.
  ///
  /// Throws a [StateError] before [bootstrap] completes.
  Map<String, List<LocalizationsDelegate<Object?>>>
  get localizationsDelegatesByMicroApp =>
      _gathered.localizationsDelegatesByMicroApp;

  /// Context each micro app received, keyed by micro app id.
  ///
  /// Throws a [StateError] before [bootstrap] completes.
  Map<String, MicroAppContext> get contexts => _gathered.contexts;

  /// Stored keys each micro app declared, keyed by micro app id.
  ///
  /// Use it for storage housekeeping that spans micro apps, such as deleting
  /// every micro app's secure keys when the user signs out. The [host]'s
  /// keys are in [hostStoredKeys].
  ///
  /// Throws a [StateError] before [bootstrap] completes.
  Map<String, Set<String>> get storedKeysByMicroApp =>
      _gathered.storedKeysByMicroApp;

  /// Stored keys the [host] declared, as [bootstrap] read them.
  ///
  /// Throws a [StateError] before [bootstrap] completes.
  Set<String> get hostStoredKeys => _gathered.hostStoredKeys;

  /// Endpoints each micro app offers, data and UI, keyed by micro app id.
  ///
  /// The container has already registered them. Use this to list them, for
  /// example on a diagnostics screen.
  ///
  /// Throws a [StateError] before [bootstrap] completes.
  Map<String, List<InterModuleEndpoint>> get endpointsByMicroApp =>
      _gathered.endpointsByMicroApp;

  /// Endpoints the [host] offers, data and UI, already registered.
  ///
  /// Throws a [StateError] before [bootstrap] completes.
  List<InterModuleEndpoint> get hostEndpoints => _gathered.hostEndpoints;

  /// Returns whether the route at [fullPath] requires sign-in.
  ///
  /// Parameters:
  /// * [fullPath] - A route's full path pattern, its path joined to its
  ///   ancestors', such as `/accounts/details/:accountId`. go_router gives it
  ///   as `GoRouterState.fullPath`.
  ///
  /// A route requires sign-in when its own [MicroAppRoute.requiresAuthentication]
  /// is `true`, or any ancestor's is. The [host]'s routes are covered
  /// too. Returns `null` when no route has [fullPath].
  ///
  /// Throws a [StateError] before [bootstrap] completes.
  bool? requiresAuthentication(String fullPath) =>
      _gathered.facts[fullPath]?.requiresAuthentication;

  /// Returns the id of the micro app that declares the route at [fullPath].
  ///
  /// Parameters:
  /// * [fullPath] - A route's full path pattern, as for
  ///   [requiresAuthentication].
  ///
  /// Use it to attribute the current screen, for example in screen-view
  /// analytics or crash-report context. Returns `null` for one of the
  /// [host]'s routes, or when no route has [fullPath].
  ///
  /// Throws a [StateError] before [bootstrap] completes.
  String? microAppIdOf(String fullPath) =>
      _gathered.facts[fullPath]?.microAppId;

  /// Starts the micro apps and gathers their declarations.
  ///
  /// Parameters:
  /// * [communication] - The inter-module communication every context
  ///   shares; the endpoint providers are registered in it.
  /// * [contextFor] - Builds the context of each micro app, with stores
  ///   limited to its [MicroApp.storedKeys].
  ///
  /// Each micro app's initialization time is logged at debug level through
  /// its own [MicroAppContext.logger].
  ///
  /// Throws a [ModularAppStartupException] for a duplicate id, a stored key
  /// declared twice (the [host]'s included), a route path that breaks a rule
  /// (including a host route inside a micro app's namespace), or a second
  /// call. A failing
  /// [MicroApp.initialize] is logged, reported to the micro app's crash
  /// reporter, and rethrown. A [DuplicateEndpointException] from the
  /// registration propagates. After any failure, [dispose] still releases
  /// the micro apps that did initialize.
  Future<void> bootstrap({
    required InterModuleCommunication communication,
    required MicroAppContextFactory contextFor,
  }) async {
    if (_started) {
      throw const ModularAppStartupException(
        type: ModularAppStartupExceptionType.alreadyBootstrapped,
        message: 'The container has already been bootstrapped.',
      );
    }
    _started = true;

    // 1. Ids and stored keys are unique. A null owner is the host.
    final ids = <String>{};
    final keyOwners = <String, String?>{
      for (final key in host.storedKeys) key: null,
    };
    for (final microApp in microApps) {
      if (!ids.add(microApp.id)) {
        throw ModularAppStartupException(
          type: ModularAppStartupExceptionType.duplicateMicroAppId,
          message: 'Duplicate micro app id "${microApp.id}".',
        );
      }
      for (final key in microApp.storedKeys) {
        if (keyOwners.containsKey(key)) {
          final owner = keyOwners[key];
          final ownerLabel = owner == null ? 'the host' : '"$owner"';
          throw ModularAppStartupException(
            type: ModularAppStartupExceptionType.duplicateStoredKey,
            message:
                'Stored key "$key" is declared by both $ownerLabel and '
                '"${microApp.id}".',
          );
        }
        keyOwners[key] = microApp.id;
      }
    }

    // 2. One context per micro app.
    final contexts = <String, MicroAppContext>{
      for (final microApp in microApps) microApp.id: contextFor(microApp),
    };
    _contexts = contexts;

    // 3. Initialize, in order.
    for (final microApp in microApps) {
      final context = contexts[microApp.id]!;
      final stopwatch = Stopwatch()..start();
      try {
        await microApp.initialize(context);
      } on Object catch (error, stackTrace) {
        await _report(
          context,
          'Micro app failed to initialize',
          microApp.id,
          error,
          stackTrace,
        );
        rethrow;
      }
      _initialized.add(microApp);
      context.logger.debug(
        'Micro app initialized',
        context: {
          'microAppId': microApp.id,
          'durationMs': stopwatch.elapsedMilliseconds,
        },
      );
    }

    // 4. Read the declarations as they are, and check the route trees.
    final routesByMicroApp = <String, List<MicroAppRouteNode>>{
      for (final microApp in microApps)
        microApp.id: List.unmodifiable(microApp.routes),
    };
    final facts = ModularAppRouteChecks.check(
      routesByMicroApp,
      hostRoutes: host.routes,
    );
    final delegatesByMicroApp = <String, List<LocalizationsDelegate<Object?>>>{
      for (final microApp in microApps)
        microApp.id: List.unmodifiable(microApp.localizationsDelegates),
    };
    final data = <String, List<DataEndpointProvider>>{
      for (final microApp in microApps) microApp.id: microApp.dataEndpoints,
    };
    final widgets = <String, List<WidgetEndpointProvider>>{
      for (final microApp in microApps) microApp.id: microApp.widgetEndpoints,
    };

    final hostData = List<DataEndpointProvider>.of(host.dataEndpoints);
    final hostWidgets = List<WidgetEndpointProvider>.of(host.widgetEndpoints);

    // 5. Register every provider at once, the host's first.
    communication.registerProviders(
      data: [...hostData, for (final providers in data.values) ...providers],
      widgets: [
        ...hostWidgets,
        for (final providers in widgets.values) ...providers,
      ],
    );

    _declarations = _ModularAppDeclarations(
      routes: List.unmodifiable([
        ...host.routes,
        for (final nodes in routesByMicroApp.values) ...nodes,
      ]),
      routesByMicroApp: Map.unmodifiable(routesByMicroApp),
      localizationsDelegates: List.unmodifiable([
        ...host.localizationsDelegates,
        for (final delegates in delegatesByMicroApp.values) ...delegates,
      ]),
      localizationsDelegatesByMicroApp: Map.unmodifiable(delegatesByMicroApp),
      contexts: Map.unmodifiable(contexts),
      hostStoredKeys: Set.unmodifiable(host.storedKeys),
      storedKeysByMicroApp: Map.unmodifiable({
        for (final microApp in microApps)
          microApp.id: Set<String>.unmodifiable(microApp.storedKeys),
      }),
      endpointsByMicroApp: Map.unmodifiable({
        for (final microApp in microApps)
          microApp.id: List<InterModuleEndpoint>.unmodifiable([
            for (final provider in data[microApp.id]!) provider.endpoint,
            for (final provider in widgets[microApp.id]!) provider.endpoint,
          ]),
      }),
      hostEndpoints: List.unmodifiable([
        for (final provider in hostData) provider.endpoint,
        for (final provider in hostWidgets) provider.endpoint,
      ]),
      facts: Map.unmodifiable(facts),
    );
  }

  /// Releases the micro apps that initialized, in reverse order.
  ///
  /// A micro app whose [MicroApp.dispose] fails is logged through its
  /// [MicroAppContext.logger] and reported to its crash reporter, with its id
  /// only, and the remaining micro apps are still disposed.
  ///
  /// Returns each failure with the micro app's id; an empty list when every
  /// micro app disposed. Calling it again, or before [bootstrap], does
  /// nothing and returns an empty list. The gathered declarations stay
  /// readable, so a router still on screen keeps working until it is
  /// replaced.
  Future<List<(String microAppId, Object error)>> dispose() async {
    final failures = <(String, Object)>[];
    for (final microApp in _initialized.reversed) {
      try {
        await microApp.dispose();
      } on Object catch (error, stackTrace) {
        failures.add((microApp.id, error));
        await _report(
          _contexts[microApp.id]!,
          'Micro app failed to dispose',
          microApp.id,
          error,
          stackTrace,
        );
      }
    }
    _initialized.clear();
    if (_started) _disposed = true;
    return failures;
  }

  _ModularAppDeclarations get _gathered =>
      _declarations ??
      (throw StateError(
        'The micro apps are read after ModularAppContainer.bootstrap '
        'completes.',
      ));

  static Future<void> _report(
    MicroAppContext context,
    String message,
    String microAppId,
    Object error,
    StackTrace stackTrace,
  ) async {
    final details = {'microAppId': microAppId};
    context.logger.error(
      message,
      error: error,
      stackTrace: stackTrace,
      context: details,
    );
    await context.crashReporter.recordError(
      error,
      stackTrace,
      reason: message,
      context: details,
    );
  }
}

/// Everything [ModularAppContainer.bootstrap] gathered, set at once when it
/// completes.
final class _ModularAppDeclarations {
  const _ModularAppDeclarations({
    required this.routes,
    required this.routesByMicroApp,
    required this.localizationsDelegates,
    required this.localizationsDelegatesByMicroApp,
    required this.contexts,
    required this.hostStoredKeys,
    required this.storedKeysByMicroApp,
    required this.endpointsByMicroApp,
    required this.hostEndpoints,
    required this.facts,
  });

  final List<MicroAppRouteNode> routes;
  final Map<String, List<MicroAppRouteNode>> routesByMicroApp;
  final List<LocalizationsDelegate<Object?>> localizationsDelegates;
  final Map<String, List<LocalizationsDelegate<Object?>>>
  localizationsDelegatesByMicroApp;
  final Map<String, MicroAppContext> contexts;
  final Set<String> hostStoredKeys;
  final Map<String, Set<String>> storedKeysByMicroApp;
  final Map<String, List<InterModuleEndpoint>> endpointsByMicroApp;
  final List<InterModuleEndpoint> hostEndpoints;
  final Map<String, ModularAppRouteFacts> facts;
}

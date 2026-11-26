/// @docImport '../exceptions/duplicate_endpoint_exception.dart';
/// @docImport '../exceptions/modular_app_startup_exception.dart';
/// @docImport 'micro_app.dart';
/// @docImport 'modular_app_container.dart';
library;

import 'package:flutter/widgets.dart';

import '../inter_module/endpoint_provider.dart';
import '../routing/micro_app_route.dart';

/// Value that holds what the host application itself declares, next to its
/// micro apps.
///
/// Use this to give [ModularAppContainer] the host's own screens (such as
/// sign-in or settings), localization delegates, storage keys, and
/// endpoints, so they are checked, gathered, and registered together with the
/// micro apps' declarations.
///
/// This is **not** a [MicroApp]: the host already owns its services, so the
/// container gives it no context, and never initializes or disposes it. The
/// host builds its endpoint providers with its own services before it
/// creates the container.
///
/// Built-in: [ModularAppContainer.bootstrap] reads every list once, when it
/// runs, and keeps unmodifiable copies:
/// * [routes] come first in [ModularAppContainer.routes], and
///   [ModularAppContainer.requiresAuthentication] covers them.
/// * [localizationsDelegates] come first in
///   [ModularAppContainer.localizationsDelegates].
/// * [storedKeys] are checked against the micro apps' keys before any micro
///   app initializes.
/// * [dataEndpoints] and [widgetEndpoints] are registered in the same call as
///   the micro apps' providers.
///
/// Rules:
/// * Route paths follow the micro apps' path rules, except that a top-level
///   path starts with `/` and stays outside every micro app's
///   `/<microAppId>`, because the router tries the host's routes first. A
///   path that breaks a rule throws a [ModularAppStartupException].
/// * A stored key declared by the host and by a micro app throws a
///   [ModularAppStartupException] of type
///   [ModularAppStartupExceptionType.duplicateStoredKey].
/// * Endpoint addresses should use a prefix that no micro app id uses, such
///   as `/app/v1/version`. An address that a micro app also declares throws a
///   [DuplicateEndpointException].
/// * The host limits its own storage to [storedKeys]; the container only
///   keeps micro apps from declaring them.
///
/// Usage from a host:
/// ```dart
/// final container = ModularAppContainer(
///   microApps: [HomeMicroApp(), AccountsMicroApp()],
///   host: ModularAppHost(
///     routes: [
///       MicroAppRoute(
///         path: '/sign-in',
///         builder: (context, parameters, body) => const SignInScreen(),
///         requiresAuthentication: false,
///       ),
///     ],
///     localizationsDelegates: [AppLocalizations.delegate],
///     storedKeys: {'app.locale'},
///     dataEndpoints: [AppVersionProvider(appInfo)],
///   ),
/// );
/// ```
final class ModularAppHost {
  /// Creates the host's declarations.
  ///
  /// Parameters:
  /// * [routes] - The host's top-level route nodes; defaults to none.
  /// * [localizationsDelegates] - Delegates for the host's own texts;
  ///   defaults to none.
  /// * [storedKeys] - Every storage key the host uses; defaults to none.
  /// * [dataEndpoints] - Data endpoints the host offers to the micro apps;
  ///   defaults to none.
  /// * [widgetEndpoints] - UI endpoints the host offers to the micro apps;
  ///   defaults to none.
  const ModularAppHost({
    this.routes = const [],
    this.localizationsDelegates = const [],
    this.storedKeys = const {},
    this.dataEndpoints = const [],
    this.widgetEndpoints = const [],
  });

  /// Route tree of the host's own screens, as declared.
  final List<MicroAppRouteNode> routes;

  /// Localization delegates for the host's own texts.
  final List<LocalizationsDelegate<Object?>> localizationsDelegates;

  /// Every storage key the host uses, in general or secure storage.
  final Set<String> storedKeys;

  /// Data endpoints the host offers to the micro apps.
  final List<DataEndpointProvider> dataEndpoints;

  /// UI endpoints the host offers to the micro apps.
  final List<WidgetEndpointProvider> widgetEndpoints;
}

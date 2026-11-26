/// @docImport '../capabilities/session_context.dart';
/// @docImport '../exceptions/duplicate_endpoint_exception.dart';
/// @docImport '../exceptions/storage_exception.dart';
/// @docImport '../inter_module/inter_module_communication.dart';
library;

import 'package:flutter/widgets.dart';

import '../inter_module/endpoint_provider.dart';
import '../routing/micro_app_route.dart';
import 'micro_app_context.dart';

/// Contract that every micro app implements so any host can integrate it.
///
/// Use this as the single entry point of a micro app: the App Shell and
/// each standalone example integrate every micro app through it, with no
/// code specific to that micro app.
///
/// This is **not** a widget or a router configuration: the micro app
/// declares its routes, localizations, and endpoints, and the host turns
/// them into the running application.
///
/// Built-in: the host runs this sequence, using Core's reusable
/// implementation:
/// 1. Reads [id] and [storedKeys] from every micro app. A duplicate id, or a
///    key declared by two micro apps, stops startup with an error that names
///    it and both micro apps.
/// 2. Builds one [MicroAppContext] per micro app, with storage limited to
///    that micro app's [storedKeys].
/// 3. Calls [initialize] on each micro app, in a fixed order.
/// 4. Reads [routes], [localizationsDelegates], [dataEndpoints], and
///    [widgetEndpoints] from every micro app, and checks that every full
///    route path is unique. A duplicate stops startup.
/// 5. Registers every endpoint provider with one
///    [InterModuleProviderRegistration.registerProviders] call. A duplicate
///    address throws a [DuplicateEndpointException] and stops startup. From
///    here on, the set of endpoints is fixed.
/// 6. Builds the router from the route trees, guarding routes that require
///    sign-in, and runs the application.
/// 7. On teardown, calls [dispose] on each micro app in reverse order. A
///    failure is reported, and the remaining teardowns still run.
///
/// Rules:
/// * Build internal dependencies in [initialize], from the context, and
///   accept overrides through the micro app's own constructor (for example a
///   fake repository in a standalone example). There are no globals.
/// * Never call [InterModuleCommunication.register] or
///   [InterModuleCommunication.registerWidget] directly: declare providers
///   in [dataEndpoints] and [widgetEndpoints].
/// * Never import Core, another micro app, a router package, or a state
///   library at runtime.
///
/// Usage from a micro app:
/// ```dart
/// final class AccountsMicroApp implements MicroApp {
///   AccountsMicroApp({AccountsRepository? repository})
///     : _repositoryOverride = repository;
///
///   final AccountsRepository? _repositoryOverride;
///   late final AccountsRepository _repository;
///
///   @override
///   String get id => 'accounts';
///
///   @override
///   Set<String> get storedKeys => {'accounts.last_balance'};
///
///   @override
///   Future<void> initialize(MicroAppContext context) async {
///     _repository = _repositoryOverride ??
///         AccountsRepository(apiClient: context.apiClient);
///   }
///
///   @override
///   List<MicroAppRouteNode> get routes => [
///     MicroAppRoute(
///       path: '/accounts',
///       builder: (context, parameters, body) =>
///           AccountsScreen(repository: _repository),
///     ),
///   ];
///
///   @override
///   List<LocalizationsDelegate<Object?>> get localizationsDelegates =>
///       const [AccountsLocalizations.delegate];
///
///   @override
///   List<DataEndpointProvider> get dataEndpoints =>
///       [AccountsBalanceProvider(_repository)];
///
///   @override
///   List<WidgetEndpointProvider> get widgetEndpoints => const [];
///
///   @override
///   Future<void> dispose() async {}
/// }
/// ```
abstract interface class MicroApp {
  /// Identifier of the micro app, such as `accounts`.
  ///
  /// It matches `^[a-z][a-z0-9_]*$`, is unique within a host, and prefixes
  /// every identifier the micro app owns: `<id>.<name>` for flags and
  /// storage keys, and `/<id>/…` for route paths and endpoint addresses. The
  /// host reads it before [initialize].
  String get id;

  /// Every storage key the micro app uses, in general or secure storage.
  ///
  /// The host reads it before [initialize], so Core can build storage
  /// limited to these keys: any other key returns a [StorageException] of
  /// type [StorageExceptionType.undeclaredKey]. A key may be declared by
  /// only one micro app in the host. Keys should follow `<id>.<name>`, but
  /// legacy keys may be declared as they are.
  Set<String> get storedKeys;

  /// Prepares the micro app with its own contracts.
  ///
  /// Parameters:
  /// * [context] - The contracts for this micro app, with storage limited to
  ///   its [storedKeys].
  ///
  /// The host calls it exactly once, before reading any declaration below.
  /// The micro app builds its internal dependencies here. It must not rely
  /// on other modules' endpoints, which are registered only after every
  /// micro app has initialized. A failure stops startup.
  Future<void> initialize(MicroAppContext context);

  /// Route tree of the micro app's screens.
  ///
  /// The host reads it after [initialize]. Top-level paths start with
  /// `/<id>`; see [MicroAppRouteNode] for the path rules.
  List<MicroAppRouteNode> get routes;

  /// Localization delegates for the micro app's own texts; it may be empty.
  List<LocalizationsDelegate<Object?>> get localizationsDelegates;

  /// Data endpoints the micro app offers to other modules.
  ///
  /// The host reads them after [initialize] and registers them all at once.
  /// Addresses follow `/<id>/v<N>/<name>`.
  List<DataEndpointProvider> get dataEndpoints;

  /// UI endpoints the micro app offers to other modules, registered the same
  /// way as [dataEndpoints].
  List<WidgetEndpointProvider> get widgetEndpoints;

  /// Releases what [initialize] acquired.
  ///
  /// The host calls it once on teardown, in reverse initialization order,
  /// for example to cancel a subscription to [SessionContext.changes]. A
  /// failure is reported, and the other micro apps are still disposed.
  Future<void> dispose();
}

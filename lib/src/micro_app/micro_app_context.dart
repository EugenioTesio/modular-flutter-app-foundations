/// @docImport '../common/result.dart';
/// @docImport '../exceptions/storage_exception.dart';
/// @docImport 'micro_app.dart';
library;

import 'package:flutter/foundation.dart';

import '../capabilities/analytics.dart';
import '../capabilities/api_client.dart';
import '../capabilities/app_info.dart';
import '../capabilities/app_logger.dart';
import '../capabilities/crash_reporter.dart';
import '../capabilities/device_permissions.dart';
import '../capabilities/feature_flags.dart';
import '../capabilities/key_value_store.dart';
import '../capabilities/session_context.dart';
import '../inter_module/inter_module_communication.dart';
import '../routing/app_navigator.dart';

/// Bundle of every contract given to one micro app.
///
/// Use this in [MicroApp.initialize] to build the micro app's internal
/// dependencies, and keep it to make the contracts available to the micro
/// app's own UI, through constructors or a scope the micro app owns.
///
/// This is **not** a service locator or a global: each micro app receives
/// its own context, and nothing else can reach it.
///
/// Built-in: Core builds one context per micro app. Most fields are instances
/// shared by every micro app, but [crashReporter] adds that micro app's
/// [MicroApp.id] to its reports, and [keyValueStore] and
/// [secureKeyValueStore] are limited to the keys it declares in
/// [MicroApp.storedKeys], so micro apps can't overwrite each other's values.
///
/// Rules:
/// * Every field is required, so a host that forgets a contract fails to
///   compile.
/// * Equality is identity: a context is a bundle of services, not a value.
///
/// Usage from a micro app:
/// ```dart
/// @override
/// Future<void> initialize(MicroAppContext context) async {
///   _repository = AccountsRepository(
///     apiClient: context.apiClient,
///     cache: context.keyValueStore,
///   );
///   _sessionChanges = context.session.changes.listen(_onSessionChanged);
/// }
/// ```
@immutable
final class MicroAppContext {
  /// Creates a micro app context.
  ///
  /// Parameters:
  /// * [communication] - Inter-module communication, shared by every module.
  /// * [apiClient] - The backend client.
  /// * [analytics] - Product analytics.
  /// * [crashReporter] - Crash and error reporting.
  /// * [logger] - Diagnostic logging.
  /// * [featureFlags] - Remote feature flags.
  /// * [keyValueStore] - General storage, limited to the micro app's
  ///   declared keys.
  /// * [secureKeyValueStore] - Secure storage, limited to the micro app's
  ///   declared keys.
  /// * [navigator] - Navigation between screens.
  /// * [session] - The signed-in user, if any.
  /// * [devicePermissions] - Operating-system permissions.
  /// * [appInfo] - Facts about the running application.
  const MicroAppContext({
    required this.communication,
    required this.apiClient,
    required this.analytics,
    required this.crashReporter,
    required this.logger,
    required this.featureFlags,
    required this.keyValueStore,
    required this.secureKeyValueStore,
    required this.navigator,
    required this.session,
    required this.devicePermissions,
    required this.appInfo,
  });

  /// Inter-module communication, used to request data and UI from other
  /// modules.
  final InterModuleCommunication communication;

  /// Client that is the micro app's only path to the backend.
  final ApiClient apiClient;

  /// Product analytics for events and screen views.
  final Analytics analytics;

  /// Crash reporter for errors the micro app handles or can't recover from.
  final CrashReporter crashReporter;

  /// Logger for diagnostic entries.
  final AppLogger logger;

  /// Feature flags, with change notifications.
  final FeatureFlags featureFlags;

  /// General storage, limited to the micro app's declared keys.
  ///
  /// Any operation on another key returns an [Err] holding a
  /// [StorageException] of type [StorageExceptionType.undeclaredKey].
  final KeyValueStore keyValueStore;

  /// Secure storage, limited to the micro app's declared keys, in the same
  /// way as [keyValueStore].
  final SecureKeyValueStore secureKeyValueStore;

  /// Navigator for opening screens by location, including other micro apps'.
  final AppNavigator navigator;

  /// Session that tells whether a user is signed in, with change
  /// notifications.
  final SessionContext session;

  /// Device permissions, for checking and requesting operating-system
  /// permissions.
  final DevicePermissions devicePermissions;

  /// Facts about the running application, such as its version.
  final AppInfo appInfo;
}

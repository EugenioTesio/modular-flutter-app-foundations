/// Library of the shared contracts of the modular Flutter app: the only
/// package a micro app depends on.
///
/// Use this as the single Foundations import in micro apps, Core, and hosts.
/// It provides:
///
/// * **Inter-module communication**: [InterModuleCommunication], with
///   [DataEndpointProvider] and [WidgetEndpointProvider], so micro apps
///   exchange data and UI without importing each other.
/// * **Capabilities**, written in the application's own vocabulary so no
///   micro app depends on a vendor: [AppInfo], [ApiClient], [Analytics],
///   [CrashReporter], [AppLogger], [FeatureFlags], [KeyValueStore] and
///   [SecureKeyValueStore], [AppNavigator], [SessionContext], and
///   [DevicePermissions].
/// * **Micro app integration**: [MicroApp], [MicroAppContext], and the
///   router-neutral route tree ([MicroAppRoute] and [MicroAppRouteGroup]),
///   so any host integrates any micro app the same way.
/// * **Outcomes and exceptions**: [Result] with [Ok] and [Err], and the
///   exceptions [ApiException], [StorageException], [NavigationException],
///   and [DuplicateEndpointException].
/// * **The unified design system**, re-exported unchanged: tokens such as
///   [DsSpacing] and [DsColors], the themes [DsTheme.light] and
///   [DsTheme.dark], and components such as [DsPageScaffold], [DsButton], and
///   [DsTextField].
/// * **The state-management contract** `switchable_state`, re-exported
///   unchanged: declare state with [AppState], read it below a [StateScope],
///   and keep screen state with [StateStoreOwner]. The host picks the
///   [StateAdapter]; micro apps never construct one.
///
/// This is **not** an implementation: every contract is an interface that
/// Core implements.
///
/// Built-in: Core gives each micro app its own instances through its context.
/// There are no global instances, so tests replace any contract with a
/// hand-written fake.
///
/// Usage from a micro app:
/// ```dart
/// import 'package:foundations/foundations.dart';
///
/// final class AccountsOverview {
///   AccountsOverview({required this.apiClient, required this.logger});
///
///   final ApiClient apiClient;
///   final AppLogger logger;
///
///   Future<List<Object?>> load() async {
///     switch (await apiClient.get('/accounts')) {
///       case Ok(:final value):
///         return value.body! as List<Object?>;
///       case Err(:final failure):
///         logger.warning('Accounts unavailable', error: failure);
///         return const [];
///     }
///   }
/// }
/// ```
///
/// Testing support for Core (the inter-module conformance check) lives in
/// `package:foundations/testing.dart`.
///
/// @docImport 'package:design_system/design_system.dart';
/// @docImport 'package:switchable_state/switchable_state.dart';
/// @docImport 'src/capabilities/analytics.dart';
/// @docImport 'src/capabilities/api_client.dart';
/// @docImport 'src/capabilities/app_info.dart';
/// @docImport 'src/capabilities/app_logger.dart';
/// @docImport 'src/capabilities/crash_reporter.dart';
/// @docImport 'src/capabilities/device_permissions.dart';
/// @docImport 'src/capabilities/feature_flags.dart';
/// @docImport 'src/capabilities/key_value_store.dart';
/// @docImport 'src/capabilities/session_context.dart';
/// @docImport 'src/common/result.dart';
/// @docImport 'src/exceptions/api_exception.dart';
/// @docImport 'src/exceptions/duplicate_endpoint_exception.dart';
/// @docImport 'src/exceptions/navigation_exception.dart';
/// @docImport 'src/exceptions/storage_exception.dart';
/// @docImport 'src/inter_module/endpoint_provider.dart';
/// @docImport 'src/inter_module/inter_module_communication.dart';
/// @docImport 'src/inter_module/inter_module_endpoint.dart';
/// @docImport 'src/inter_module/inter_module_response.dart';
/// @docImport 'src/inter_module/inter_module_status.dart';
/// @docImport 'src/inter_module/inter_module_value.dart';
/// @docImport 'src/micro_app/micro_app.dart';
/// @docImport 'src/micro_app/micro_app_context.dart';
/// @docImport 'src/routing/app_navigator.dart';
/// @docImport 'src/routing/micro_app_route.dart';
library;

// Delivered packages, re-exported unchanged: no show, hide, or renames.
export 'package:design_system/design_system.dart';
export 'package:switchable_state/switchable_state.dart';

export 'src/capabilities/analytics.dart';
export 'src/capabilities/api_client.dart';
export 'src/capabilities/app_info.dart';
export 'src/capabilities/app_logger.dart';
export 'src/capabilities/crash_reporter.dart';
export 'src/capabilities/device_permissions.dart';
export 'src/capabilities/feature_flags.dart';
export 'src/capabilities/key_value_store.dart';
export 'src/capabilities/session_context.dart';
export 'src/common/result.dart';
export 'src/exceptions/api_exception.dart';
export 'src/exceptions/duplicate_endpoint_exception.dart';
export 'src/exceptions/navigation_exception.dart';
export 'src/exceptions/storage_exception.dart';
export 'src/inter_module/endpoint_provider.dart';
export 'src/inter_module/inter_module_communication.dart';
export 'src/inter_module/inter_module_endpoint.dart';
export 'src/inter_module/inter_module_response.dart';
export 'src/inter_module/inter_module_status.dart';
export 'src/inter_module/inter_module_value.dart';
export 'src/micro_app/micro_app.dart';
export 'src/micro_app/micro_app_context.dart';
export 'src/routing/app_navigator.dart';
export 'src/routing/micro_app_route.dart';

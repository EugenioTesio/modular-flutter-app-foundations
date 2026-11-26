// In-memory fakes for the eleven capability contracts (FR-026, FR-027).
//
// Each one runs without a device, platform channels, network access, or Core,
// which is what lets micro app tests run headless (SC-007).
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:foundations/foundations.dart';

// ---------------------------------------------------------------------------
// Application information
// ---------------------------------------------------------------------------

/// Fixed application facts.
final class FakeAppInfo implements AppInfo {
  /// Creates application facts with test defaults.
  const FakeAppInfo({
    this.appName = 'Sample',
    this.version = '1.4.0',
    this.buildNumber = '42',
    this.environment = AppInfoEnvironment.development,
  });

  @override
  final String appName;
  @override
  final String version;
  @override
  final String buildNumber;
  @override
  final AppInfoEnvironment environment;
}

// ---------------------------------------------------------------------------
// API client
// ---------------------------------------------------------------------------

/// Answers every request with a canned result and records what it was sent.
final class RecordingApiClient implements ApiClient {
  /// Creates a client that answers `Ok(ApiResponse(statusCode: 200))` unless
  /// [respond] says otherwise.
  RecordingApiClient({
    Result<ApiResponse, ApiException> Function(ApiRequest request)? respond,
  }) : _respond = respond ?? ((_) => const Ok(ApiResponse(statusCode: 200)));

  final Result<ApiResponse, ApiException> Function(ApiRequest request) _respond;

  /// Every request sent, in order.
  final List<ApiRequest> requests = [];

  @override
  Future<Result<ApiResponse, ApiException>> send(ApiRequest request) async {
    requests.add(request);
    return _respond(request);
  }
}

// ---------------------------------------------------------------------------
// Analytics and crash reporting
// ---------------------------------------------------------------------------

/// Records events and screen views as `(name, properties)` pairs.
final class RecordingAnalytics implements Analytics {
  /// Every event logged, in order.
  final List<(String, Map<String, Object>)> events = [];

  /// Every screen view logged, in order.
  final List<(String, Map<String, Object>)> screenViews = [];

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object> properties = const {},
  }) async => events.add((name, properties));

  @override
  Future<void> logScreenView(
    String screenName, {
    Map<String, Object> properties = const {},
  }) async => screenViews.add((screenName, properties));
}

/// Accepts every call and does nothing.
final class NoOpAnalytics implements Analytics {
  /// Creates a no-op analytics implementation.
  const NoOpAnalytics();

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object> properties = const {},
  }) async {}

  @override
  Future<void> logScreenView(
    String screenName, {
    Map<String, Object> properties = const {},
  }) async {}
}

/// Records reported errors and the current user identifier.
final class RecordingCrashReporter implements CrashReporter {
  /// Every error reported, with its reason.
  final List<(Object, String?)> errors = [];

  /// The pseudonymous identifier last set, or null.
  String? userIdentifier;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, Object> context = const {},
  }) async => errors.add((error, reason));

  @override
  Future<void> setUserIdentifier(String? pseudonymousId) async =>
      userIdentifier = pseudonymousId;
}

/// Accepts every call and does nothing.
final class NoOpCrashReporter implements CrashReporter {
  /// Creates a no-op crash reporter.
  const NoOpCrashReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, Object> context = const {},
  }) async {}

  @override
  Future<void> setUserIdentifier(String? pseudonymousId) async {}
}

// ---------------------------------------------------------------------------
// Logging
// ---------------------------------------------------------------------------

/// One entry received by [RecordingAppLogger].
@immutable
final class LogEntry {
  /// Creates an entry.
  const LogEntry(
    this.level,
    this.message, {
    this.error,
    this.stackTrace,
    this.context = const {},
  });

  /// The entry's level.
  final LogLevel level;

  /// The entry's message.
  final String message;

  /// The failure, if any.
  final Object? error;

  /// The failure's stack trace, if any.
  final StackTrace? stackTrace;

  /// Structured values.
  final Map<String, Object> context;

  @override
  bool operator ==(Object other) =>
      other is LogEntry &&
      other.level == level &&
      other.message == message &&
      other.error == error &&
      other.stackTrace == stackTrace &&
      mapEquals(other.context, context);

  @override
  int get hashCode => Object.hash(level, message, error, stackTrace);

  @override
  String toString() =>
      'LogEntry(${level.name}, $message, error: $error, context: $context)';
}

/// Records every entry it receives.
final class RecordingAppLogger implements AppLogger {
  /// Every entry, in order.
  final List<LogEntry> entries = [];

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object> context = const {},
  }) => entries.add(
    LogEntry(
      level,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    ),
  );
}

/// Writes one line per entry, as a standalone example would.
final class ConsoleAppLogger implements AppLogger {
  /// Creates a console logger writing through [write], which defaults to
  /// `debugPrint`.
  ConsoleAppLogger({void Function(String line)? write})
    : _write = write ?? debugPrint;

  final void Function(String line) _write;

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object> context = const {},
  }) {
    final suffix = [
      if (context.isNotEmpty) '$context',
      if (error != null) 'error: $error',
    ].join(' ');
    _write(
      '[${level.name.toUpperCase()}] $message${suffix.isEmpty ? '' : ' $suffix'}',
    );
  }
}

/// Accepts every entry and does nothing.
final class NoOpAppLogger implements AppLogger {
  /// Creates a no-op logger.
  const NoOpAppLogger();

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object> context = const {},
  }) {}
}

// ---------------------------------------------------------------------------
// Feature flags
// ---------------------------------------------------------------------------

/// Holds flag values in memory. [refresh] replaces them and emits on
/// [changes].
final class InMemoryFeatureFlags implements FeatureFlags {
  /// Creates flags holding [values], keyed by flag key.
  InMemoryFeatureFlags([Map<String, Object> values = const {}])
    : _values = Map.of(values);

  Map<String, Object> _values;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  T valueOf<T extends Object>(FeatureFlag<T> flag) {
    final value = _values[flag.key];
    return value is T ? value : flag.defaultValue;
  }

  @override
  Stream<void> get changes => _changes.stream;

  /// Replaces every value with [values] and notifies listeners.
  void refresh(Map<String, Object> values) {
    _values = Map.of(values);
    _changes.add(null);
  }

  /// Closes [changes].
  Future<void> close() => _changes.close();
}

// ---------------------------------------------------------------------------
// Storage
// ---------------------------------------------------------------------------

/// Stores values in [entries], limited to [declaredKeys] the way Core limits
/// a micro app's store to its `storedKeys`.
class InMemoryKeyValueStore implements KeyValueStore {
  /// Creates a store over [entries] (shared between stores to model one
  /// device), allowing only [declaredKeys].
  InMemoryKeyValueStore({
    required this.declaredKeys,
    Map<String, String>? entries,
  }) : entries = entries ?? {};

  /// The keys this store may touch.
  final Set<String> declaredKeys;

  /// The underlying values.
  final Map<String, String> entries;

  Err<R, StorageException>? _undeclared<R>(String key) =>
      declaredKeys.contains(key)
      ? null
      : Err(
          StorageException(type: StorageExceptionType.undeclaredKey, key: key),
        );

  @override
  Future<Result<String?, StorageException>> read(String key) async =>
      _undeclared<String?>(key) ?? Ok(entries[key]);

  @override
  Future<Result<void, StorageException>> write(String key, String value) async {
    final failure = _undeclared<void>(key);
    if (failure != null) return failure;
    entries[key] = value;
    return const Ok(null);
  }

  @override
  Future<Result<void, StorageException>> delete(String key) async {
    final failure = _undeclared<void>(key);
    if (failure != null) return failure;
    entries.remove(key);
    return const Ok(null);
  }

  @override
  Future<Result<bool, StorageException>> containsKey(String key) async =>
      _undeclared<bool>(key) ?? Ok(entries.containsKey(key));
}

/// The secure counterpart of [InMemoryKeyValueStore].
final class InMemorySecureKeyValueStore extends InMemoryKeyValueStore
    implements SecureKeyValueStore {
  /// Creates a secure store over [entries], allowing only [declaredKeys].
  InMemorySecureKeyValueStore({required super.declaredKeys, super.entries});
}

// ---------------------------------------------------------------------------
// Navigation
// ---------------------------------------------------------------------------

/// Knows a fixed set of route patterns, keeps a stack of locations, and
/// records every navigation.
final class FakeAppNavigator implements AppNavigator {
  /// Creates a navigator that knows `routes` (patterns such as
  /// `/accounts/details/:accountId`) and starts at [initialPath].
  FakeAppNavigator({this._routes = const {}, String initialPath = '/'})
    : stack = [initialPath];

  final Set<String> _routes;

  /// The current locations, bottom first.
  final List<String> stack;

  /// What the next successful [push] or [replace] completes with, as if the
  /// screen had already closed.
  NavigationResult nextResult = const RouteCancelled();

  /// Every location pushed, with its body.
  final List<(String, Map<String, Object>)> pushed = [];

  /// Every [pop] call's result.
  final List<Map<String, Object>?> popped = [];

  bool _matches(String path) {
    final segments = Uri.parse(path).pathSegments;
    return _routes.any((route) {
      final pattern = Uri.parse(route).pathSegments;
      if (pattern.length != segments.length) return false;
      for (var i = 0; i < pattern.length; i++) {
        final matches = pattern[i].startsWith(':')
            ? segments[i].isNotEmpty
            : pattern[i] == segments[i];
        if (!matches) return false;
      }
      return true;
    });
  }

  @override
  Future<Result<NavigationResult, NavigationException>> push(
    String path, {
    Map<String, Object> body = const {},
  }) async {
    if (!_matches(path)) return Err(RouteNotFoundException(path));
    pushed.add((path, body));
    return Ok(nextResult);
  }

  @override
  Result<void, NavigationException> go(
    String path, {
    Map<String, Object> body = const {},
  }) {
    if (!_matches(path)) return Err(RouteNotFoundException(path));
    stack
      ..clear()
      ..add(path);
    return const Ok(null);
  }

  @override
  Future<Result<NavigationResult, NavigationException>> replace(
    String path, {
    Map<String, Object> body = const {},
  }) async {
    if (!_matches(path)) return Err(RouteNotFoundException(path));
    stack
      ..removeLast()
      ..add(path);
    return Ok(nextResult);
  }

  @override
  void pop({Map<String, Object>? result}) {
    popped.add(result);
    if (stack.length > 1) stack.removeLast();
  }

  @override
  Result<void, NavigationException> popUntil(String path) {
    if (!stack.contains(path)) return Err(RouteNotFoundException(path));
    while (stack.last != path) {
      stack.removeLast();
    }
    return const Ok(null);
  }
}

// ---------------------------------------------------------------------------
// Session and device permissions
// ---------------------------------------------------------------------------

/// A session that tests move between states explicitly.
final class FakeSessionContext implements SessionContext {
  /// Creates a session starting at [initial].
  FakeSessionContext([SessionState initial = const Unauthenticated()])
    : _current = initial;

  SessionState _current;
  final StreamController<SessionState> _changes =
      StreamController<SessionState>.broadcast();

  @override
  SessionState get current => _current;

  @override
  Stream<SessionState> get changes => _changes.stream;

  /// Moves to [state] and notifies listeners.
  void emit(SessionState state) {
    _current = state;
    _changes.add(state);
  }

  /// Closes [changes].
  Future<void> close() => _changes.close();
}

/// Answers permission checks, requests, and service checks from canned maps.
final class FakeDevicePermissions implements DevicePermissions {
  /// Creates device permissions. Unknown permissions start as
  /// [DevicePermissionStatus.denied]. A request on a denied permission
  /// "prompts" and returns the matching entry in `answers`, or denied.
  /// Services not in `services` are
  /// [DevicePermissionServiceStatus.notApplicable].
  FakeDevicePermissions({
    Map<DevicePermission, DevicePermissionStatus> statuses = const {},
    this._answers = const {},
    this._services = const {},
  }) : _statuses = Map.of(statuses);

  final Map<DevicePermission, DevicePermissionStatus> _statuses;
  final Map<DevicePermission, DevicePermissionStatus> _answers;
  final Map<DevicePermission, DevicePermissionServiceStatus> _services;

  /// Every permission for which the system prompt was shown.
  final List<DevicePermission> prompted = [];

  /// How many times the system settings were opened.
  int settingsOpened = 0;

  @override
  Future<DevicePermissionStatus> status(DevicePermission permission) async =>
      _statuses[permission] ?? DevicePermissionStatus.denied;

  @override
  Future<DevicePermissionStatus> request(DevicePermission permission) async {
    final current = await status(permission);
    if (current != DevicePermissionStatus.denied) return current;
    prompted.add(permission);
    final answer = _answers[permission] ?? DevicePermissionStatus.denied;
    _statuses[permission] = answer;
    return answer;
  }

  @override
  Future<DevicePermissionServiceStatus> serviceStatus(
    DevicePermission permission,
  ) async =>
      _services[permission] ?? DevicePermissionServiceStatus.notApplicable;

  @override
  Future<bool> openAppSettings() async {
    settingsOpened++;
    return true;
  }
}

/// Context factories built from the fakes above, as static helpers.
abstract final class FakeMicroAppContexts {
  /// Returns a [MicroAppContextFactory] whose contexts share [communication]
  /// and one instance of every other fake, with stores limited to each micro
  /// app's declared keys over one shared, initially empty store.
  static MicroAppContextFactory factory({
    required InterModuleCommunication communication,
    AppLogger logger = const NoOpAppLogger(),
    CrashReporter crashReporter = const NoOpCrashReporter(),
  }) {
    final entries = <String, String>{};
    final secureEntries = <String, String>{};
    final apiClient = RecordingApiClient();
    final featureFlags = InMemoryFeatureFlags();
    final navigator = FakeAppNavigator();
    final session = FakeSessionContext();
    final devicePermissions = FakeDevicePermissions();
    return (microApp) => MicroAppContext(
      communication: communication,
      apiClient: apiClient,
      analytics: const NoOpAnalytics(),
      crashReporter: crashReporter,
      logger: logger,
      featureFlags: featureFlags,
      keyValueStore: InMemoryKeyValueStore(
        declaredKeys: microApp.storedKeys,
        entries: entries,
      ),
      secureKeyValueStore: InMemorySecureKeyValueStore(
        declaredKeys: microApp.storedKeys,
        entries: secureEntries,
      ),
      navigator: navigator,
      session: session,
      devicePermissions: devicePermissions,
      appInfo: const FakeAppInfo(),
    );
  }
}

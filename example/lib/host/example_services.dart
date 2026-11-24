import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:foundations/foundations.dart';

/// In-memory stand-ins for the contracts Core implements in a real app.
///
/// They let the example host build a full [MicroAppContext] for every
/// module with no backend, plugin, or vendor SDK.

/// Answers requests from canned bodies, keyed by path, after a short delay.
final class ExampleApiClient implements ApiClient {
  /// Creates a client that answers each path in [responses]; any other path
  /// fails with a 404 client error.
  ExampleApiClient({
    this.responses = const {},
    this.delay = const Duration(milliseconds: 300),
  });

  /// Canned response bodies by path.
  final Map<String, Object?> responses;

  /// How long each request takes.
  final Duration delay;

  @override
  Future<Result<ApiResponse, ApiException>> send(ApiRequest request) async {
    await Future<void>.delayed(delay);
    if (!responses.containsKey(request.path)) {
      return const Err(
        ApiException(type: ApiExceptionType.clientError, statusCode: 404),
      );
    }
    return Ok(ApiResponse(statusCode: 200, body: responses[request.path]));
  }
}

/// Prints analytics events to the debug console.
final class ExampleAnalytics implements Analytics {
  /// Creates the analytics stand-in.
  const ExampleAnalytics();

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object> properties = const {},
  }) async => debugPrint('[analytics] $name $properties');

  @override
  Future<void> logScreenView(
    String screenName, {
    Map<String, Object> properties = const {},
  }) async => debugPrint('[analytics] screen $screenName $properties');
}

/// Prints recorded errors to the debug console.
final class ExampleCrashReporter implements CrashReporter {
  /// Creates the crash reporter stand-in.
  const ExampleCrashReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, Object> context = const {},
  }) async => debugPrint('[crash] ${reason ?? error} $context');

  @override
  Future<void> setUserIdentifier(String? pseudonymousId) async {}
}

/// Prints log entries to the debug console.
final class ExampleAppLogger implements AppLogger {
  /// Creates the logger stand-in.
  const ExampleAppLogger();

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object> context = const {},
  }) => debugPrint('[${level.name}] $message $context');
}

/// Serves every flag's default value; flags never change.
final class ExampleFeatureFlags implements FeatureFlags {
  /// Creates the feature flags stand-in.
  const ExampleFeatureFlags();

  @override
  T valueOf<T extends Object>(FeatureFlag<T> flag) => flag.defaultValue;

  @override
  Stream<void> get changes => const Stream.empty();
}

/// Key-value storage over a map shared by every module, limited to the keys
/// one module declared.
class ExampleKeyValueStore implements KeyValueStore {
  /// Creates a store over [entries] that allows only [declaredKeys].
  ExampleKeyValueStore({required this.declaredKeys, required this.entries});

  /// The keys this module declared in its `storedKeys`.
  final Set<String> declaredKeys;

  /// The entries shared by every module's store.
  final Map<String, String> entries;

  Result<T, StorageException>? _undeclared<T>(String key) =>
      declaredKeys.contains(key)
      ? null
      : Err(
          StorageException(type: StorageExceptionType.undeclaredKey, key: key),
        );

  @override
  Future<Result<String?, StorageException>> read(String key) async =>
      _undeclared(key) ?? Ok(entries[key]);

  @override
  Future<Result<void, StorageException>> write(String key, String value) async {
    final undeclared = _undeclared<void>(key);
    if (undeclared != null) return undeclared;
    entries[key] = value;
    return const Ok(null);
  }

  @override
  Future<Result<void, StorageException>> delete(String key) async {
    final undeclared = _undeclared<void>(key);
    if (undeclared != null) return undeclared;
    entries.remove(key);
    return const Ok(null);
  }

  @override
  Future<Result<bool, StorageException>> containsKey(String key) async =>
      _undeclared(key) ?? Ok(entries.containsKey(key));
}

/// Secure storage stand-in: the same rules, over its own map.
final class ExampleSecureKeyValueStore extends ExampleKeyValueStore
    implements SecureKeyValueStore {
  /// Creates a secure store over [entries] that allows only [declaredKeys].
  ExampleSecureKeyValueStore({
    required super.declaredKeys,
    required super.entries,
  });
}

/// A session the host can change, for the demo's signed-out and
/// no-permission scenarios. Micro apps only read it.
final class ExampleSessionContext implements SessionContext {
  /// Creates a session that starts in [initial].
  ExampleSessionContext(SessionState initial) : _current = initial;

  SessionState _current;
  final _changes = StreamController<SessionState>.broadcast();

  @override
  SessionState get current => _current;

  @override
  Stream<SessionState> get changes => _changes.stream;

  /// Changes the session, as Core does after sign-in or sign-out.
  void set(SessionState state) {
    if (state == _current) return;
    _current = state;
    _changes.add(state);
  }

  /// Closes the change stream.
  Future<void> close() => _changes.close();
}

/// Grants every permission.
final class ExampleDevicePermissions implements DevicePermissions {
  /// Creates the permissions stand-in.
  const ExampleDevicePermissions();

  @override
  Future<DevicePermissionStatus> status(DevicePermission permission) async =>
      DevicePermissionStatus.granted;

  @override
  Future<DevicePermissionStatus> request(DevicePermission permission) async =>
      DevicePermissionStatus.granted;

  @override
  Future<DevicePermissionServiceStatus> serviceStatus(
    DevicePermission permission,
  ) async => DevicePermissionServiceStatus.enabled;

  @override
  Future<bool> openAppSettings() async => false;
}

/// Facts about the example app.
final class ExampleAppInfo implements AppInfo {
  /// Creates the app info stand-in.
  const ExampleAppInfo();

  @override
  String get appName => 'Foundations example';

  @override
  String get version => '0.1.0';

  @override
  String get buildNumber => '1';

  @override
  AppInfoEnvironment get environment => AppInfoEnvironment.development;
}

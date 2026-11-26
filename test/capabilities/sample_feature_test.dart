// Feature: A micro app feature runs on every capability contract with fakes
// only (US2 acceptance scenarios 1, 2, 4, 5, 6, 7, 9, 10, 11, 14; SC-005,
// SC-007). No device, network, platform channel, or Core is involved.
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';

import '../support/fakes.dart';

// ---------------------------------------------------------------------------
// The sample feature: an "accounts overview" that uses all eleven
// capabilities through their contracts and nothing else.
// ---------------------------------------------------------------------------

const _showSavings = BoolFeatureFlag(
  key: 'accounts.show_savings',
  defaultValue: false,
);
const _nearbyBranches = LocationDevicePermission(
  accuracy: LocationDevicePermissionAccuracy.approximate,
);
const _lastBalanceKey = 'accounts.last_balance';
const _deviceIdKey = 'accounts.device_id';

sealed class OverviewOutcome {
  const OverviewOutcome();
}

final class OverviewShown extends OverviewOutcome {
  const OverviewShown({required this.balance, required this.showSavings});
  final num balance;
  final bool showSavings;

  @override
  bool operator ==(Object other) =>
      other is OverviewShown &&
      other.balance == balance &&
      other.showSavings == showSavings;

  @override
  int get hashCode => Object.hash(balance, showSavings);

  @override
  String toString() => 'OverviewShown($balance, showSavings: $showSavings)';
}

final class OverviewSignedOut extends OverviewOutcome {
  const OverviewSignedOut();
}

final class OverviewSessionExpired extends OverviewOutcome {
  const OverviewSessionExpired();
}

final class OverviewUnavailable extends OverviewOutcome {
  const OverviewUnavailable(this.cachedBalance);
  final String? cachedBalance;

  @override
  bool operator ==(Object other) =>
      other is OverviewUnavailable && other.cachedBalance == cachedBalance;

  @override
  int get hashCode => cachedBalance.hashCode;
}

final class AccountsOverview {
  AccountsOverview({
    required this.appInfo,
    required this.apiClient,
    required this.analytics,
    required this.crashReporter,
    required this.logger,
    required this.featureFlags,
    required this.store,
    required this.secureStore,
    required this.navigator,
    required this.session,
    required this.permissions,
  });

  final AppInfo appInfo;
  final ApiClient apiClient;
  final Analytics analytics;
  final CrashReporter crashReporter;
  final AppLogger logger;
  final FeatureFlags featureFlags;
  final KeyValueStore store;
  final SecureKeyValueStore secureStore;
  final AppNavigator navigator;
  final SessionContext session;
  final DevicePermissions permissions;

  String get footer =>
      '${appInfo.appName} ${appInfo.version} (${appInfo.buildNumber})';

  bool get showSavings => featureFlags.valueOf(_showSavings);

  Stream<String> get greetings => session.changes.map(
    (state) => switch (state) {
      Authenticated(:final identity) => 'Hi ${identity.userId}',
      Unauthenticated() => 'Signed out',
    },
  );

  Future<OverviewOutcome> load() async {
    await analytics.logScreenView('accounts.overview');
    logger.debug('loading overview');

    if (session.current case Unauthenticated()) {
      logger.info('overview needs sign-in');
      return const OverviewSignedOut();
    }
    if (await secureStore.read(_deviceIdKey) case Ok(:final value?)) {
      await crashReporter.setUserIdentifier(value);
    }

    switch (await apiClient.get('/accounts/summary')) {
      case Ok(:final value):
        final body = value.body! as Map<String, Object?>;
        final balance = body['balance']! as num;
        await store.write(_lastBalanceKey, '$balance');
        await analytics.logEvent(
          'accounts.overview_loaded',
          properties: {'showSavings': showSavings},
        );
        logger.info('overview loaded');
        return OverviewShown(balance: balance, showSavings: showSavings);
      case Err(failure: ApiException(type: ApiExceptionType.unauthorized)):
        logger.warning('session expired');
        return const OverviewSessionExpired();
      case Err(:final failure):
        await crashReporter.recordError(
          failure,
          null,
          reason: 'overview failed',
        );
        logger.error('overview failed', error: failure);
        final cached = await store.read(_lastBalanceKey);
        return OverviewUnavailable(switch (cached) {
          Ok(:final value) => value,
          Err() => null,
        });
    }
  }

  /// Opens the account's details screen, telling it where the user came from.
  Future<Result<NavigationResult, NavigationException>> openDetails(
    String accountId,
  ) => navigator.push(
    '/accounts/details/$accountId',
    body: {'source': 'overview'},
  );

  /// Opens a screen no micro app declares.
  Future<Result<NavigationResult, NavigationException>> openStatements() =>
      navigator.push('/accounts/statements');

  /// Turns on "branches near me", which needs an approximate location.
  Future<bool> enableNearbyBranches() async {
    switch (await permissions.request(_nearbyBranches)) {
      case DevicePermissionStatus.granted || DevicePermissionStatus.limited:
        final service = await permissions.serviceStatus(_nearbyBranches);
        return service != DevicePermissionServiceStatus.disabled;
      case DevicePermissionStatus.permanentlyDenied:
        await permissions.openAppSettings();
        return false;
      case DevicePermissionStatus.provisional ||
          DevicePermissionStatus.denied ||
          DevicePermissionStatus.restricted ||
          DevicePermissionStatus.unsupported:
        return false;
    }
  }
}

// ---------------------------------------------------------------------------
// Test wiring
// ---------------------------------------------------------------------------

const _ana = Authenticated(UserIdentity(userId: 'u1', displayName: 'Ana'));

Result<ApiResponse, ApiException> _balance(ApiRequest _) =>
    const Ok(ApiResponse(statusCode: 200, body: {'balance': 120.5}));

final class Harness {
  Harness({
    SessionState session = _ana,
    Map<DevicePermission, DevicePermissionStatus> statuses = const {},
    Map<DevicePermission, DevicePermissionStatus> answers = const {},
    Map<DevicePermission, DevicePermissionServiceStatus> services = const {},
    Result<ApiResponse, ApiException> Function(ApiRequest)? respond,
    this.analytics,
    this.crashReporter,
    this.logger,
  }) : session = FakeSessionContext(session),
       permissions = FakeDevicePermissions(
         statuses: statuses,
         answers: answers,
         services: services,
       ),
       apiClient = RecordingApiClient(respond: respond ?? _balance),
       flags = InMemoryFeatureFlags();

  final FakeSessionContext session;
  final FakeDevicePermissions permissions;
  final RecordingApiClient apiClient;
  final InMemoryFeatureFlags flags;
  final Analytics? analytics;
  final CrashReporter? crashReporter;
  final AppLogger? logger;

  final recordingAnalytics = RecordingAnalytics();
  final recordingCrashReporter = RecordingCrashReporter();
  final recordingLogger = RecordingAppLogger();
  final navigator = FakeAppNavigator(
    routes: {'/accounts', '/accounts/details/:accountId'},
    initialPath: '/accounts',
  );
  final store = InMemoryKeyValueStore(declaredKeys: {_lastBalanceKey});
  final secureStore = InMemorySecureKeyValueStore(
    declaredKeys: {_deviceIdKey},
    entries: {_deviceIdKey: 'device-7f3a'},
  );

  late final feature = AccountsOverview(
    appInfo: const FakeAppInfo(appName: 'Accounts', version: '1.4.0'),
    apiClient: apiClient,
    analytics: analytics ?? recordingAnalytics,
    crashReporter: crashReporter ?? recordingCrashReporter,
    logger: logger ?? recordingLogger,
    featureFlags: flags,
    store: store,
    secureStore: secureStore,
    navigator: navigator,
    session: session,
    permissions: permissions,
  );
}

Result<ApiResponse, ApiException> Function(ApiRequest) _failWith(
  ApiExceptionType type,
) =>
    (_) => Err(ApiException(type: type));

void main() {
  group('Given a feature that shows the application version (scenario 1)', () {
    test('When it runs on a fake AppInfo, '
        'Then its footer shows the name, version, and build', () {
      // Given
      final harness = Harness();

      // When
      final footer = harness.feature.footer;

      // Then
      expect(footer, 'Accounts 1.4.0 (42)');
    });
  });

  group('Given a signed-in user (scenario 2)', () {
    test('When the overview loads on fakes only, '
        'Then it shows the balance and uses each capability', () async {
      // Given
      final harness = Harness();

      // When
      final outcome = await harness.feature.load();

      // Then
      expect(outcome, const OverviewShown(balance: 120.5, showSavings: false));
      expect(harness.apiClient.requests.single.path, '/accounts/summary');
      expect(harness.store.entries, {_lastBalanceKey: '120.5'});
      expect(harness.recordingCrashReporter.userIdentifier, 'device-7f3a');
      expect(
        harness.recordingAnalytics.screenViews.single.$1,
        'accounts.overview',
      );
      expect(
        harness.recordingAnalytics.events.single.$1,
        'accounts.overview_loaded',
      );
      expect(harness.recordingLogger.entries.map((e) => e.level), [
        LogLevel.debug,
        LogLevel.info,
      ]);
    });
  });

  group('Given no-op analytics, crash reporting, and logging (scenario 4)', () {
    final responders =
        <String, Result<ApiResponse, ApiException> Function(ApiRequest)>{
          'success': _balance,
          'server error': _failWith(ApiExceptionType.serverError),
          'session expired': _failWith(ApiExceptionType.unauthorized),
        };

    for (final MapEntry(key: name, value: respond) in responders.entries) {
      test(
        'When the overview loads with a $name response, '
        'Then the outcome equals the one with recording implementations',
        () async {
          // Given
          final recording = Harness(respond: respond);
          final noOp = Harness(
            respond: respond,
            analytics: const NoOpAnalytics(),
            crashReporter: const NoOpCrashReporter(),
            logger: const NoOpAppLogger(),
          );

          // When
          final withRecording = await recording.feature.load();
          final withNoOp = await noOp.feature.load();

          // Then
          expect(withNoOp, withRecording);
        },
      );
    }
  });

  group('Given no user is signed in (scenario 5)', () {
    test('When the overview loads, '
        'Then the session is explicitly Unauthenticated and no backend call '
        'is made', () async {
      // Given
      final harness = Harness(session: const Unauthenticated());

      // When
      final outcome = await harness.feature.load();

      // Then
      expect(harness.session.current, const Unauthenticated());
      expect(outcome, isA<OverviewSignedOut>());
      expect(harness.apiClient.requests, isEmpty);
    });
  });

  group('Given a signed-in user and a feature observing the session '
      '(scenario 6)', () {
    test('When the user signs out, Then the feature is notified', () async {
      // Given
      final harness = Harness();
      final greetings = <String>[];
      final subscription = harness.feature.greetings.listen(greetings.add);

      // When
      harness.session.emit(const Unauthenticated());
      await pumpEventQueue();

      // Then
      expect(greetings, ['Signed out']);
      await subscription.cancel();
      await harness.session.close();
    });
  });

  group('Given a feature that opens screens by location (scenario 7)', () {
    test(
      'When the location matches a route and its screen returns a result, '
      'Then the caller receives Ok(RouteCompleted) and the body arrives',
      () async {
        // Given
        final harness = Harness();
        harness.navigator.nextResult = const RouteCompleted({'closed': true});

        // When
        final outcome = await harness.feature.openDetails('a1');

        // Then
        expect(
          outcome,
          const Ok<NavigationResult, NavigationException>(
            RouteCompleted({'closed': true}),
          ),
        );
        final (path, body) = harness.navigator.pushed.single;
        expect(path, '/accounts/details/a1');
        expect(body, {'source': 'overview'});
      },
    );

    test('When the location matches no route, '
        'Then the caller receives Err(RouteNotFoundException)', () async {
      // Given
      final harness = Harness();

      // When
      final outcome = await harness.feature.openStatements();

      // Then
      expect(
        outcome,
        const Err<NavigationResult, NavigationException>(
          RouteNotFoundException('/accounts/statements'),
        ),
      );
      expect(harness.navigator.pushed, isEmpty);
    });
  });

  group('Given location access is not decided yet', () {
    test(
      'When the feature enables nearby branches and the user allows it, '
      'Then the system prompt is shown once for approximate location',
      () async {
        // Given
        final harness = Harness(
          answers: {_nearbyBranches: DevicePermissionStatus.granted},
        );

        // When
        final enabled = await harness.feature.enableNearbyBranches();

        // Then
        expect(enabled, isTrue);
        expect(harness.permissions.prompted, [_nearbyBranches]);
      },
    );
  });

  group('Given location access is granted but location services are off', () {
    test(
      'When the feature enables nearby branches, '
      'Then it stays off, because the permission alone is not enough',
      () async {
        // Given
        final harness = Harness(
          statuses: {_nearbyBranches: DevicePermissionStatus.granted},
          services: {_nearbyBranches: DevicePermissionServiceStatus.disabled},
        );

        // When
        final enabled = await harness.feature.enableNearbyBranches();

        // Then
        expect(enabled, isFalse);
        expect(harness.permissions.prompted, isEmpty);
      },
    );
  });

  group('Given location access was permanently denied', () {
    test('When the feature enables nearby branches, '
        'Then no prompt is shown and the system settings open', () async {
      // Given
      final harness = Harness(
        statuses: {_nearbyBranches: DevicePermissionStatus.permanentlyDenied},
      );

      // When
      final enabled = await harness.feature.enableNearbyBranches();

      // Then
      expect(enabled, isFalse);
      expect(harness.permissions.prompted, isEmpty);
      expect(harness.permissions.settingsOpened, 1);
    });
  });

  group('Given the session has expired (scenario 9)', () {
    test('When the overview loads, '
        'Then the feature sees the unauthorized failure type', () async {
      // Given
      final harness = Harness(
        respond: _failWith(ApiExceptionType.unauthorized),
      );

      // When
      final outcome = await harness.feature.load();

      // Then
      expect(outcome, isA<OverviewSessionExpired>());
      expect(harness.recordingCrashReporter.errors, isEmpty);
    });
  });

  group('Given the backend fails after an earlier successful load', () {
    test(
      'When the overview loads again, '
      'Then the error is reported and the cached balance is offered',
      () async {
        // Given
        var fail = false;
        final harness = Harness(
          respond: (request) => fail
              ? const Err(ApiException(type: ApiExceptionType.serverError))
              : _balance(request),
        );
        await harness.feature.load();
        fail = true;

        // When
        final outcome = await harness.feature.load();

        // Then
        expect(outcome, const OverviewUnavailable('120.5'));
        expect(
          harness.recordingCrashReporter.errors.single.$2,
          'overview failed',
        );
      },
    );
  });

  group('Given a flag provider that does not know the flag (scenario 10)', () {
    test('When the feature reads the flag, Then it receives the default', () {
      // Given
      final harness = Harness();

      // When
      final showSavings = harness.feature.showSavings;

      // Then
      expect(showSavings, isFalse);
    });
  });

  group('Given a standalone example configured with console logging '
      '(scenario 11)', () {
    test('When the feature writes entries at different levels, '
        'Then each appears on the console with its level', () async {
      // Given
      final lines = <String>[];
      final harness = Harness(
        respond: _failWith(ApiExceptionType.serverError),
        logger: ConsoleAppLogger(write: lines.add),
      );

      // When
      await harness.feature.load();

      // Then
      expect(lines.first, '[DEBUG] loading overview');
      expect(lines.last, startsWith('[ERROR] overview failed'));
    });
  });

  group('Given a feature listening for flag changes (scenario 14)', () {
    test('When the flag provider refreshes, '
        'Then the feature is notified and re-reads its flag', () async {
      // Given
      final harness = Harness();
      final reads = <bool>[];
      final subscription = harness.flags.changes.listen(
        (_) => reads.add(harness.feature.showSavings),
      );

      // When
      harness.flags.refresh({'accounts.show_savings': true});
      await pumpEventQueue();

      // Then
      expect(reads, [true]);
      await subscription.cancel();
      await harness.flags.close();
    });
  });

  group('Given a store limited to the feature declared keys', () {
    test('When the feature touches another micro app key, '
        'Then it receives undeclaredKey and nothing is written', () async {
      // Given
      final harness = Harness();

      // When
      final result = await harness.store.write('transfers.draft', '{}');

      // Then
      expect(
        result,
        const Err<void, StorageException>(
          StorageException(
            type: StorageExceptionType.undeclaredKey,
            key: 'transfers.draft',
          ),
        ),
      );
      expect(harness.store.entries, isEmpty);
    });
  });
}

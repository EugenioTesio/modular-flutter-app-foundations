// Feature: A host that forgets a contract fails to compile (data-model.md
// "MicroAppContext": every field is required; quickstart.md V5).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';

import '../support/fakes.dart';
import '../support/reference_inter_module_communication.dart';

void main() {
  group('Given a MicroAppContext built without one contract', () {
    test('When the fixture is analyzed, '
        'Then the analyzer reports only missing_required_argument for it', () {
      // Given
      const fixture = 'test/fixtures/missing_contract_fixture.dart';

      // When
      final result = Process.runSync('dart', [
        'analyze',
        '--format=machine',
        fixture,
      ]);

      // Then
      final errors = '${result.stdout}'
          .split('\n')
          .where((line) => line.startsWith('ERROR|'))
          .toList();
      expect(errors, hasLength(1), reason: '${result.stdout}');
      expect(errors.single, contains('MISSING_REQUIRED_ARGUMENT'));
      expect(errors.single, contains("'appInfo'"));
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('Given every contract', () {
    test('When a MicroAppContext is built, '
        'Then each field holds the contract it was given', () {
      // Given
      final communication = ReferenceInterModuleCommunication();
      final apiClient = RecordingApiClient();
      const analytics = NoOpAnalytics();
      const crashReporter = NoOpCrashReporter();
      const logger = NoOpAppLogger();
      final featureFlags = InMemoryFeatureFlags();
      final keyValueStore = InMemoryKeyValueStore(declaredKeys: const {});
      final secureKeyValueStore = InMemorySecureKeyValueStore(
        declaredKeys: const {},
      );
      final navigator = FakeAppNavigator();
      final session = FakeSessionContext();
      final devicePermissions = FakeDevicePermissions();
      const appInfo = FakeAppInfo();

      // When
      final context = MicroAppContext(
        communication: communication,
        apiClient: apiClient,
        analytics: analytics,
        crashReporter: crashReporter,
        logger: logger,
        featureFlags: featureFlags,
        keyValueStore: keyValueStore,
        secureKeyValueStore: secureKeyValueStore,
        navigator: navigator,
        session: session,
        devicePermissions: devicePermissions,
        appInfo: appInfo,
      );

      // Then
      expect(context.communication, same(communication));
      expect(context.apiClient, same(apiClient));
      expect(context.analytics, same(analytics));
      expect(context.crashReporter, same(crashReporter));
      expect(context.logger, same(logger));
      expect(context.featureFlags, same(featureFlags));
      expect(context.keyValueStore, same(keyValueStore));
      expect(context.secureKeyValueStore, same(secureKeyValueStore));
      expect(context.navigator, same(navigator));
      expect(context.session, same(session));
      expect(context.devicePermissions, same(devicePermissions));
      expect(context.appInfo, same(appInfo));
    });
  });
}

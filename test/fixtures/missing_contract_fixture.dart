// Fixture for test/micro_app/micro_app_context_test.dart. It must NOT
// compile: the MicroAppContext below leaves out `appInfo`, and every field is
// required, so the analyzer reports `missing_required_argument`. The
// directory is excluded from normal analysis.
import 'package:foundations/foundations.dart';

import '../support/fakes.dart';
import '../support/reference_inter_module_communication.dart';

/// A host that forgot to pass [AppInfo].
MicroAppContext buildContextWithoutAppInfo() => MicroAppContext(
  communication: ReferenceInterModuleCommunication(),
  apiClient: RecordingApiClient(),
  analytics: const NoOpAnalytics(),
  crashReporter: const NoOpCrashReporter(),
  logger: const NoOpAppLogger(),
  featureFlags: InMemoryFeatureFlags(),
  keyValueStore: InMemoryKeyValueStore(declaredKeys: const {}),
  secureKeyValueStore: InMemorySecureKeyValueStore(declaredKeys: const {}),
  navigator: FakeAppNavigator(),
  session: FakeSessionContext(),
  devicePermissions: FakeDevicePermissions(),
);

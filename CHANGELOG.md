# Changelog

All notable changes to Foundations. The package follows
[semantic versioning](https://semver.org): below 1.0.0, a breaking change
bumps the minor version. Releases are git tags `vX.Y.Z`.

Each entry has the same sections, even when one is empty, and states the
versions of the two packages it delivers. Adopting a breaking change in either
of them makes the Foundations release breaking too.

## 0.1.0

First release.

**Delivers**

- `design_system` **0.1.0**, the interim package in `packages/design_system`
  at this same commit. See its [changelog](packages/design_system/CHANGELOG.md).
- `switchable_state` **0.1.0**, pinned exactly.

Both are re-exported unchanged from `package:foundations/foundations.dart`.

### Added

- **Inter-module communication**: `InterModuleCommunication` with data and
  widget endpoints, `InterModuleEndpoint` (address, parameters, required
  parameters, and an optional trace name), `InterModuleCommunicationResponse`
  with `isSuccess`, the four statuses in `InterModuleStatusCode`, the shared
  codes in `InterModuleErrorCode`, the payload rule
  `InterModuleValidator.isValidPayload`, and `EndpointType`.
- **Endpoint providers**: `DataEndpointProvider` and
  `WidgetEndpointProvider`, registered in one step with `registerProviders`.
- **Capabilities**: `AppInfo`, `ApiClient` (with `ApiRequest`, `ApiResponse`,
  and the `get`/`post`/`put`/`patch`/`delete` shortcuts), `Analytics`,
  `CrashReporter`, `AppLogger` (with level shortcuts), `FeatureFlags` (bool,
  string, and number flags with defaults, and change notifications),
  `KeyValueStore` and `SecureKeyValueStore` (limited to declared keys),
  `SessionContext` (`Authenticated` and `Unauthenticated`, `UserIdentity`),
  and `DevicePermissions` (one sealed `DevicePermission` per operating-system
  permission, with options such as location access and accuracy).
- **Micro app integration**: `MicroApp`, `MicroAppContext`, and the
  router-neutral route tree `MicroAppRoute` and `MicroAppRouteGroup`, with
  `AppNavigator` and `NavigationResult`.
- **Outcomes and exceptions**: `Result` (`Ok` and `Err`), `ApiException`,
  `StorageException`, `NavigationException` (`RouteNotFoundException`), and
  `DuplicateEndpointException`.
- **Testing support**: `package:foundations/testing.dart` with the
  inter-module conformance check `InterModuleConformance` (cases C01–C17),
  for Core and for standalone stubs.
- Value types print only names and statuses, never values, so printing a
  request, response, failure, endpoint, or identity can't leak credentials or
  personal data into logs.

### Changed

None.

### Deprecated

None.

### Removed

None.

### Breaking

None. This is the first release.

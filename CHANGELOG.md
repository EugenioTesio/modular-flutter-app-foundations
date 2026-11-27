# Changelog

All notable changes to Foundations. The package follows
[semantic versioning](https://semver.org): below 1.0.0, a breaking change
bumps the minor version. Releases are git tags `vX.Y.Z`.

Each entry has the same sections, even when one is empty, and states the
versions of the two packages it delivers. Adopting a breaking change in either
of them makes the Foundations release breaking too.

## 0.1.1

Delivers design_system 0.1.1 from its own repository.

**Delivers**

- `design_system` **0.1.1**, from its own repository,
  [`modular-flutter-app-design-system`](https://github.com/EugenioTesio/modular-flutter-app-design-system),
  pinned by the git tag `v0.1.1`. See its
  [changelog](https://github.com/EugenioTesio/modular-flutter-app-design-system/blob/v0.1.1/CHANGELOG.md).
  The package, its public library, and its behavior are unchanged.
- `switchable_state` **0.1.0**, pinned exactly.

Both are re-exported unchanged from `package:foundations/foundations.dart`.

### Added

None.

### Changed

- `design_system` now comes from its own repository through a git tag,
  instead of from `packages/design_system` in this repository. Micro apps
  change no code.
- `tool/git_consumer_smoke.sh` checks that a git consumer resolves exactly
  one `design_system`, from its repository at the pinned tag.
- The README explains how to develop against a local Design System checkout.

### Deprecated

None.

### Removed

- The interim folder `packages/design_system/`.

### Breaking

None.

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
- **Modular app container**: `ModularAppContainer`, `ModularAppHost`, and
  `MicroAppContextFactory`. The container runs the host sequence: it checks
  ids, stored keys, and route trees, the host's own declarations
  (`ModularAppHost`: routes, delegates, stored keys, endpoints) included,
  builds one context per micro app,
  initializes the micro apps, registers their endpoints, and disposes them in
  reverse order. It hands the routes and localization delegates over as
  declared, combined (the host's first) or by micro app, and offers `requiresAuthentication`
  and `microAppIdOf` lookups by full path.
- **Outcomes and exceptions**: `Result` (`Ok` and `Err`), `ApiException`,
  `StorageException`, `NavigationException` (`RouteNotFoundException`),
  `DuplicateEndpointException`, and `ModularAppStartupException` (with
  `ModularAppStartupExceptionType`).
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

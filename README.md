# Foundations

Foundations holds the shared contracts of the modular Flutter app. It is the
only package a micro app depends on. With it, micro apps exchange data and UI
without importing each other, use platform capabilities without depending on
a vendor, and plug into any host the same way.

Foundations contains contracts only. Core implements them and gives each micro
app its own instances through a `MicroAppContext`. There are no global
instances, so a test can replace any contract with a hand-written fake.

Foundations also delivers two first-party packages, re-exported unchanged:

- `design_system`: tokens, themes, and accessible components.
- `switchable_state`: the state-management contract. The host chooses the
  adapter.

`CHANGELOG.md` states which version of each package a release delivers.

## Entry points

| Import | For | Provides |
|--------|-----|----------|
| `package:foundations/foundations.dart` | Micro apps, Core, hosts | Every contract, plus the re-exported `design_system` and `switchable_state` |
| `package:foundations/testing.dart` | Test suites of Core and stubs | `InterModuleConformance`, which checks an `InterModuleCommunication` implementation |

Nothing under `lib/src/` can be imported directly.

## Adding the dependency

Depend on a release tag:

```yaml
dependencies:
  foundations:
    git:
      url: https://github.com/EugenioTesio/modular-flutter-app-foundations.git
      ref: v0.1.0
```

Do not add `design_system` or `switchable_state` yourself. Pub resolves them
through Foundations, so every module uses the same versions.

## Guide: publish data in one micro app and use it in another

This guide connects two micro apps. Accounts publishes an account's balance at
`/accounts/v1/balance`, and Transfers reads it. Neither one imports the other.
Each depends only on Foundations.

### 1. Describe the endpoint in the providing micro app

Addresses follow `/<module>/v<N>/<name>`. The provider declares its required
parameters, and the contract enforces them for every caller.

```dart
// accounts/lib/src/balance_provider.dart
import 'package:foundations/foundations.dart';

final class AccountsBalanceProvider implements DataEndpointProvider {
  const AccountsBalanceProvider({required this.apiClient});

  final ApiClient apiClient;

  @override
  InterModuleEndpoint get endpoint => const InterModuleEndpoint(
    url: '/accounts/v1/balance',
    requiredParameters: {'accountId'},
  );

  @override
  Future<InterModuleCommunicationResponse<Map<String, Object?>>> handle(
    Map<String, Object?> parameters,
  ) async {
    final accountId = parameters['accountId'];
    if (accountId is! String || accountId.isEmpty) {
      return const InterModuleCommunicationResponse.failure(
        statusCode: InterModuleStatusCode.badRequest,
        errorCode: 'invalid_account_id',
      );
    }
    switch (await apiClient.get('/accounts/$accountId/balance')) {
      case Ok(:final value):
        final body = value.body! as Map<String, Object?>;
        // Only primitives, lists, and maps cross module boundaries.
        return InterModuleCommunicationResponse.success({
          'accountId': accountId,
          'available': body['available'],
          'currency': body['currency'],
        });
      case Err(failure: ApiException(statusCode: 404)):
        return const InterModuleCommunicationResponse.failure(
          statusCode: InterModuleStatusCode.notFound,
          errorCode: 'account_not_found',
        );
      case Err():
        return const InterModuleCommunicationResponse.failure(
          statusCode: InterModuleStatusCode.internalError,
        );
    }
  }
}
```

### 2. Declare the provider in the micro app

The host registers every declared provider in one step after it initializes
the micro apps. A micro app never registers endpoints any other way.

```dart
// accounts/lib/accounts.dart
final class AccountsMicroApp implements MicroApp {
  late final MicroAppContext _context;

  @override
  String get id => 'accounts';

  @override
  Future<void> initialize(MicroAppContext context) async => _context = context;

  @override
  List<DataEndpointProvider> get dataEndpoints => [
    AccountsBalanceProvider(apiClient: _context.apiClient),
  ];

  // storedKeys, routes, widgetEndpoints, localizationsDelegates, dispose …
}
```

### 3. Request the data from the consuming micro app

Transfers knows only the address and the shape of the map. It branches on the
status, and on the error code when it needs to.

```dart
// transfers/lib/src/source_account.dart
Future<String> describeSource(
  InterModuleCommunication communication,
  String accountId,
) async {
  final response = await communication.request(
    endpoint: InterModuleEndpoint(
      url: '/accounts/v1/balance',
      parameters: {'accountId': accountId},
      traceName: 'transfers.source_balance',
    ),
  );
  return switch ((response.statusCode, response.errorCode)) {
    (InterModuleStatusCode.ok, _) =>
      'Available: ${response.data!['available']} ${response.data!['currency']}',
    (InterModuleStatusCode.badRequest, InterModuleErrorCode.unauthenticated) =>
      'Sign in to continue.',
    (InterModuleStatusCode.badRequest, _) => 'Choose an account.',
    (InterModuleStatusCode.notFound, InterModuleErrorCode.endpointNotRegistered) =>
      'Accounts is not available in this application.',
    (InterModuleStatusCode.notFound, _) => 'The account was not found.',
    _ => 'Something went wrong. Please try again.',
  };
}
```

Transfers gets `communication` from its own `MicroAppContext`.

### 4. Handle every outcome

The statuses are application outcomes, not HTTP responses. There are exactly
four:

| Status | Meaning | Error code |
|--------|---------|------------|
| 200 | Success; `data` holds the map | none |
| 400 | The request was refused | `missing_required_parameters` (a required parameter is absent or `null`), `unauthenticated`, `forbidden`, or the provider's own code |
| 404 | Nothing answered | `endpoint_not_registered` (the providing micro app isn't installed), or the provider's own code |
| 500 | The provider failed | none, and no exception text reaches the caller |

`response.isSuccess` is true exactly for 200–299.

### 5. Test both sides without a host

- **Provider**: call `handle` directly with a fake `ApiClient`.
- **Consumer**: pass a hand-written fake `InterModuleCommunication` that
  returns each of the four outcomes.
- **Communication implementation** (Core or a stub): run
  `InterModuleConformance.cases` from `package:foundations/testing.dart`.

To share UI instead of data, follow the same steps with a
`WidgetEndpointProvider` and `getWidget`. The provider returns its widget
synchronously, and the widget loads its own data and shows its own loading and
error states.

The runnable example in [`example/`](example/) shows all of this with three
micro apps: Home, Transfers, and Cards.

```bash
cd example && flutter run
```

## Inclusion rules

Every micro app, Core, and every host depends on Foundations, so its public
surface stays small. A change is rejected when it adds any of the following:

- **Feature models**, such as an account, card, or transfer response. They
  stay in the micro app that owns them and cross module boundaries as maps
  through inter-module communication.
- **Business entitlements.** The permissions contract covers only device
  permissions. Who may see or do what is decided by the micro app that owns
  the data.
- **Wrappers around `design_system` or `switchable_state`.** Both are
  re-exported unchanged, with no wrappers, renames, or `show`/`hide` lists.
- **A new capability.** The capability set is fixed: app info, API client,
  analytics, crash reporting, logging, feature flags, key-value storage
  (general and secure), navigation, session, and device permissions. Adding
  one needs a specification change first.
- **Implementations, vendor types, global state, or new runtime
  dependencies.** The runtime dependencies are `flutter`, `design_system`,
  and `switchable_state`.

## Versioning and deprecation

- Foundations follows semantic versioning, and releases are git tags `vX.Y.Z`.
  Below 1.0.0 a breaking change bumps the minor version; from 1.0.0 on, it
  bumps the major version.
- Removing, renaming, or changing a public element in a way that breaks
  callers or implementers is a breaking change. Its changelog entry includes
  migration notes.
- Adopting a breaking `design_system` or `switchable_state` release makes the
  Foundations release breaking too.
- A public element is marked `@Deprecated`, naming its replacement, for at
  least one minor release before it is removed.
- An endpoint changes incompatibly under a new versioned address, such as
  `/cards/v2/home-banner`. The provider keeps serving the old address until
  its consumers have moved.
- Each `CHANGELOG.md` entry has Added, Changed, Deprecated, Removed, and
  Breaking sections. It also states the `design_system` and
  `switchable_state` versions the release delivers.

The pull request template walks through these checks.

## Moving the Design System to its own repository

`design_system` lives in [`packages/design_system`](packages/design_system)
until it moves to `modular-flutter-app-design-system`. Moving it changes no
consumer code:

1. In this repository, split out its history and push it to the new
   repository, then tag the release:

   ```bash
   git subtree split --prefix=packages/design_system -b design-system-split
   git push https://github.com/EugenioTesio/modular-flutter-app-design-system.git design-system-split:main
   ```

   Then create the tag `v<version>` in the new repository.
2. In `pubspec.yaml`, replace the path dependency with the tag, and delete
   `packages/design_system/`:

   ```yaml
   design_system:
     git:
       url: https://github.com/EugenioTesio/modular-flutter-app-design-system.git
       ref: v<version>
   ```

3. Nothing else changes. The package name, the public library, and the
   re-export line stay the same, so micro apps change no code.
4. To develop both repositories side by side, use a `pubspec_overrides.yaml`
   that points to `../design-system`. Keep it git-ignored and never commit it.

## Development

| Check | Command |
|-------|---------|
| Analyze (0 issues) | `flutter analyze` |
| Tests | `flutter test` |
| API docs (0 warnings) | `dart doc --dry-run` |
| Coverage (at least 90% of `lib/`) | `flutter test --coverage`, which writes `coverage/lcov.info` |
| Git consumer resolution | `tool/git_consumer_smoke.sh` |

There is no CI. Run these before opening a pull request, in this package,
the example, the design system, and its gallery.

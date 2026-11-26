// Sample micro apps built only on Foundations (quickstart.md V5 and V10).
//
// Accounts and Transfers model two teams' micro apps: each declares its
// stored keys, a route tree, and endpoint providers. Home and Auth are tiny
// micro apps that give the router a landing page and a sign-in page.
import 'package:flutter/material.dart';
import 'package:foundations/foundations.dart';

// ---------------------------------------------------------------------------
// Base
// ---------------------------------------------------------------------------

/// A configurable micro app that records its lifecycle in [journal].
///
/// Its declarations throw a [StateError] when read before [initialize], which
/// proves the host reads them in the right order.
class SampleMicroApp implements MicroApp {
  /// Creates a sample micro app.
  SampleMicroApp({
    required this.id,
    this.storedKeys = const {},
    List<String>? journal,
    this.failOnDispose = false,
    List<MicroAppRouteNode> Function(SampleMicroApp app)? routes,
    List<DataEndpointProvider> Function(MicroAppContext context)? data,
    List<WidgetEndpointProvider> Function(MicroAppContext context)? widgets,
  }) : journal = journal ?? [],
       _routes = routes ?? ((_) => const []),
       _data = data ?? ((_) => const []),
       _widgets = widgets ?? ((_) => const []);

  @override
  final String id;

  @override
  final Set<String> storedKeys;

  /// Lifecycle events, such as `accounts.initialize`, shared between micro
  /// apps to observe ordering.
  final List<String> journal;

  /// Whether [dispose] throws, to prove the host keeps tearing down.
  final bool failOnDispose;

  final List<MicroAppRouteNode> Function(SampleMicroApp app) _routes;
  final List<DataEndpointProvider> Function(MicroAppContext context) _data;
  final List<WidgetEndpointProvider> Function(MicroAppContext context) _widgets;

  MicroAppContext? _context;

  /// The context received in [initialize].
  MicroAppContext get context =>
      _context ?? (throw StateError('$id was read before initialize.'));

  @override
  Future<void> initialize(MicroAppContext context) async {
    if (_context != null) throw StateError('$id initialized twice.');
    _context = context;
    journal.add('$id.initialize');
  }

  @override
  List<MicroAppRouteNode> get routes {
    context; // Throws before initialize.
    return _routes(this);
  }

  @override
  List<LocalizationsDelegate<Object?>> get localizationsDelegates {
    context;
    return const [DefaultMaterialLocalizations.delegate];
  }

  @override
  List<DataEndpointProvider> get dataEndpoints => _data(context);

  @override
  List<WidgetEndpointProvider> get widgetEndpoints => _widgets(context);

  @override
  Future<void> dispose() async {
    journal.add('$id.dispose');
    if (failOnDispose) throw StateError('$id failed to dispose.');
  }
}

// ---------------------------------------------------------------------------
// Accounts
// ---------------------------------------------------------------------------

/// The Accounts micro app: account screens, a picker that returns a choice,
/// a full-screen statement, a tab group with grouped state, and balance
/// endpoints.
class SampleAccountsMicroApp extends SampleMicroApp {
  /// Creates the Accounts micro app.
  SampleAccountsMicroApp({
    Set<String> extraStoredKeys = const {},
    super.journal,
    super.failOnDispose,
    List<MicroAppRouteNode> extraRoutes = const [],
  }) : super(
         id: 'accounts',
         storedKeys: {'accounts.last_balance', ...extraStoredKeys},
         routes: (app) => [
           ...(app as SampleAccountsMicroApp)._accountsRoutes(),
           ...extraRoutes,
         ],
         data: (context) => [AccountsBalanceProvider(context.apiClient)],
         widgets: (context) => [const AccountsBalanceCardProvider()],
       );

  /// State shared by the tab group, closed when the user leaves it.
  final AppState<int> tabVisits = AppState<int>.grouped(
    () => 0,
    debugName: 'accounts.tab_visits',
  );

  List<MicroAppRouteNode> _accountsRoutes() => [
    MicroAppRoute(
      path: '/accounts',
      builder: (context, parameters, body) =>
          SampleScreen(title: 'Accounts', parameters: parameters, body: body),
      routes: [
        // Opts out of sign-in, but inherits it from '/accounts'.
        MicroAppRoute(
          path: 'details/:accountId',
          requiresAuthentication: false,
          builder: (context, parameters, body) => SampleScreen(
            title: 'Account details',
            parameters: parameters,
            body: body,
          ),
        ),
      ],
    ),
    MicroAppRoute(
      path: '/accounts/picker',
      builder: (context, parameters, body) =>
          SamplePickerScreen(navigator: this.context.navigator),
    ),
    MicroAppRoute(
      path: '/accounts/statement',
      presentation: RoutePresentation.fullscreenDialog,
      builder: (context, parameters, body) =>
          SampleScreen(title: 'Statement', parameters: parameters, body: body),
    ),
    MicroAppRouteGroup(
      builder: (context, child) => SampleTabsLayout(
        journal: journal,
        child: StateScope.group(owns: [tabVisits], child: child),
      ),
      routes: [
        for (final tab in const ['overview', 'history'])
          MicroAppRoute(
            path: '/accounts/tabs/$tab',
            builder: (context, parameters, body) =>
                SampleTabScreen(tab: tab, visits: tabVisits),
          ),
      ],
    ),
  ];
}

/// Data endpoint `/accounts/v1/balance`: an account's balance, loaded
/// through the API client.
final class AccountsBalanceProvider implements DataEndpointProvider {
  /// Creates the provider over [apiClient].
  const AccountsBalanceProvider(this.apiClient);

  /// The backend client.
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
    return switch (await apiClient.get('/accounts/$accountId/balance')) {
      Ok(:final value) => InterModuleCommunicationResponse.success({
        'accountId': accountId,
        'balance': value.body,
      }),
      Err(
        failure: ApiException(
          type: ApiExceptionType.clientError,
          statusCode: 404,
        ),
      ) =>
        const InterModuleCommunicationResponse.failure(
          statusCode: InterModuleStatusCode.notFound,
          errorCode: 'account_not_found',
        ),
      Err() => const InterModuleCommunicationResponse.failure(
        statusCode: InterModuleStatusCode.internalError,
        errorCode: 'balance_unavailable',
      ),
    };
  }
}

/// Widget endpoint `/accounts/v1/balance-card`: a card showing an account's
/// balance, placed inside another micro app's screen.
final class AccountsBalanceCardProvider implements WidgetEndpointProvider {
  /// Creates the provider.
  const AccountsBalanceCardProvider();

  @override
  InterModuleEndpoint get endpoint => const InterModuleEndpoint(
    url: '/accounts/v1/balance-card',
    requiredParameters: {'accountId'},
  );

  @override
  InterModuleCommunicationResponse<Widget> build(
    Map<String, Object?> parameters,
  ) {
    final accountId = parameters['accountId'];
    if (accountId is! String || accountId.isEmpty) {
      return const InterModuleCommunicationResponse.failure(
        statusCode: InterModuleStatusCode.badRequest,
        errorCode: 'invalid_account_id',
      );
    }
    return InterModuleCommunicationResponse.success(
      Card(child: Text('Balance of $accountId')),
    );
  }
}

// ---------------------------------------------------------------------------
// Transfers
// ---------------------------------------------------------------------------

/// The Transfers micro app: a transfer screen and a draft-count endpoint
/// backed by its own storage.
class SampleTransfersMicroApp extends SampleMicroApp {
  /// Creates the Transfers micro app.
  SampleTransfersMicroApp({
    Set<String> extraStoredKeys = const {},
    super.journal,
  }) : super(
         id: 'transfers',
         storedKeys: {'transfers.draft', ...extraStoredKeys},
         routes: (app) => [
           MicroAppRoute(
             path: '/transfers',
             builder: (context, parameters, body) => SampleScreen(
               title: 'Transfers',
               parameters: parameters,
               body: body,
             ),
           ),
         ],
         data: (context) => [
           TransfersDraftCountProvider(context.keyValueStore),
         ],
       );
}

/// Data endpoint `/transfers/v1/draft-count`: how many transfer drafts are
/// saved (zero or one).
final class TransfersDraftCountProvider implements DataEndpointProvider {
  /// Creates the provider over Transfers' own [store].
  const TransfersDraftCountProvider(this.store);

  /// Transfers' storage, limited to its declared keys.
  final KeyValueStore store;

  @override
  InterModuleEndpoint get endpoint =>
      const InterModuleEndpoint(url: '/transfers/v1/draft-count');

  @override
  Future<InterModuleCommunicationResponse<Map<String, Object?>>> handle(
    Map<String, Object?> parameters,
  ) async => switch (await store.containsKey('transfers.draft')) {
    Ok(:final value) => InterModuleCommunicationResponse.success({
      'count': value ? 1 : 0,
    }),
    Err() => const InterModuleCommunicationResponse.failure(
      statusCode: InterModuleStatusCode.internalError,
      errorCode: 'storage_unavailable',
    ),
  };
}

// ---------------------------------------------------------------------------
// Home and Auth
// ---------------------------------------------------------------------------

/// Sample micro apps that give the router a landing page and sign-in.
abstract final class SampleMicroApps {
  /// The Home micro app, with the guarded `/home` route.
  static SampleMicroApp home({List<String>? journal}) => SampleMicroApp(
    id: 'home',
    journal: journal,
    routes: (app) => [
      MicroAppRoute(
        path: '/home',
        builder: (context, parameters, body) =>
            SampleScreen(title: 'Home', parameters: parameters, body: body),
      ),
    ],
  );

  /// The Auth micro app, with the public `/auth/sign-in` and `/auth/help`
  /// routes.
  static SampleMicroApp auth({List<String>? journal}) => SampleMicroApp(
    id: 'auth',
    journal: journal,
    routes: (app) => [
      for (final (path, title) in const [
        ('/auth/sign-in', 'Sign in'),
        ('/auth/help', 'Help'),
      ])
        MicroAppRoute(
          path: path,
          requiresAuthentication: false,
          builder: (context, parameters, body) =>
              SampleScreen(title: title, parameters: parameters, body: body),
        ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Screens
// ---------------------------------------------------------------------------

/// Shows its title, parameters, body, and presentation as text.
class SampleScreen extends StatelessWidget {
  /// Creates a screen.
  const SampleScreen({
    super.key,
    required this.title,
    required this.parameters,
    required this.body,
  });

  /// The screen's title.
  final String title;

  /// The merged path and query parameters.
  final Map<String, String> parameters;

  /// The caller's body.
  final Map<String, Object> body;

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final fullscreen = route is PageRoute && route.fullscreenDialog;
    return Scaffold(
      body: Column(
        children: [
          Text(title),
          Text('parameters: $parameters'),
          Text('body: $body'),
          Text('fullscreenDialog: $fullscreen'),
        ],
      ),
    );
  }
}

/// Lets the user pick an account or close without picking.
class SamplePickerScreen extends StatelessWidget {
  /// Creates a picker that closes through [navigator].
  const SamplePickerScreen({super.key, required this.navigator});

  /// The micro app's navigator.
  final AppNavigator navigator;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        const Text('Picker'),
        TextButton(
          onPressed: () => navigator.pop(result: {'accountId': 'a1'}),
          child: const Text('Pick a1'),
        ),
        TextButton(onPressed: navigator.pop, child: const Text('Close')),
      ],
    ),
  );
}

/// The tab group's shared layout. Records `accounts.tabs.layout.init` each
/// time it is created.
class SampleTabsLayout extends StatefulWidget {
  /// Creates the layout around [child].
  const SampleTabsLayout({
    super.key,
    required this.journal,
    required this.child,
  });

  /// Where creation is recorded.
  final List<String> journal;

  /// The current tab's screen.
  final Widget child;

  @override
  State<SampleTabsLayout> createState() => _SampleTabsLayoutState();
}

class _SampleTabsLayoutState extends State<SampleTabsLayout> {
  @override
  void initState() {
    super.initState();
    widget.journal.add('accounts.tabs.layout.init');
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Text('Tabs layout'),
      Expanded(child: widget.child),
    ],
  );
}

/// One tab, showing and incrementing the group's visit count.
class SampleTabScreen extends StatelessWidget {
  /// Creates a tab screen.
  const SampleTabScreen({super.key, required this.tab, required this.visits});

  /// The tab's name.
  final String tab;

  /// The grouped visit count.
  final AppState<int> visits;

  @override
  Widget build(BuildContext context) {
    final store = StateScope.of(context).store(visits);
    return Scaffold(
      body: Column(
        children: [
          Text('Tab $tab'),
          store.watch((count) => Text('visits: $count')),
          TextButton(
            onPressed: () => store.update((count) => count + 1),
            child: const Text('Visit'),
          ),
        ],
      ),
    );
  }
}

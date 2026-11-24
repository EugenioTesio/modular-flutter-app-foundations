import 'package:flutter/material.dart';
import 'package:foundations/foundations.dart';

/// Home as a micro app: the first screen, at `/home`. Home owns no cards or
/// transfers: it places the widgets that Cards and Transfers hand out, asking
/// for them through its context's communication. It never imports another
/// module.
final class HomeMicroApp implements MicroApp {
  late final MicroAppContext _context;

  @override
  String get id => 'home';

  @override
  Set<String> get storedKeys => const {};

  @override
  Future<void> initialize(MicroAppContext context) async => _context = context;

  @override
  List<MicroAppRouteNode> get routes => [
    MicroAppRoute(
      path: '/home',
      builder: (context, parameters, body) =>
          HomeScreen(communication: _context.communication),
    ),
  ];

  @override
  List<LocalizationsDelegate<Object?>> get localizationsDelegates => const [];

  @override
  List<DataEndpointProvider> get dataEndpoints => const [];

  @override
  List<WidgetEndpointProvider> get widgetEndpoints => const [];

  @override
  Future<void> dispose() async {}
}

/// Home's screen: Cards' banner, then Transfers' shortcut.
///
/// Home sends no parameters: what each widget shows, and where it leads, is
/// its owner's business. When a widget can't be built, Home shows its own
/// fallback in that place.
class HomeScreen extends StatelessWidget {
  /// Creates the screen.
  const HomeScreen({super.key, required this.communication});

  /// The inter-module communication contract.
  final InterModuleCommunication communication;

  /// Cards' banner.
  static const cardsBanner = InterModuleEndpoint(url: '/cards/v1/home-banner');

  /// Transfers' shortcut.
  static const transfersShortcut = InterModuleEndpoint(
    url: '/transfers/v1/home-shortcut',
  );

  @override
  Widget build(BuildContext context) {
    return DsPageScaffold(
      title: 'Home',
      body: ListView(
        children: [
          HomeWidgetSlot(
            communication: communication,
            endpoint: cardsBanner,
            notInstalled: const DsEmptyState(
              icon: Icons.credit_card_off,
              title: 'Cards is not available',
              message:
                  'Your cards appear here when the Cards feature is installed.',
            ),
            failed: const DsInlineMessage(
              tone: DsMessageTone.error,
              message: 'Card details are unavailable right now.',
            ),
          ),
          const SizedBox(height: DsSpacing.lg),
          HomeWidgetSlot(
            communication: communication,
            endpoint: transfersShortcut,
            notInstalled: const SizedBox.shrink(),
            failed: const DsInlineMessage(
              tone: DsMessageTone.error,
              message: 'Transfers is unavailable right now.',
            ),
          ),
        ],
      ),
    );
  }
}

/// A place on Home for a widget another micro app owns.
///
/// It asks for [endpoint]'s widget synchronously; the widget loads its own
/// data after it is placed. It shows [notInstalled] when no micro app
/// provides the endpoint, and [failed] for any other failure.
class HomeWidgetSlot extends StatelessWidget {
  /// Creates a slot.
  const HomeWidgetSlot({
    super.key,
    required this.communication,
    required this.endpoint,
    required this.notInstalled,
    required this.failed,
  });

  /// The inter-module communication contract.
  final InterModuleCommunication communication;

  /// The widget endpoint to place.
  final InterModuleEndpoint endpoint;

  /// What Home shows when no micro app provides [endpoint].
  final Widget notInstalled;

  /// What Home shows when the widget can't be built for any other reason.
  final Widget failed;

  @override
  Widget build(BuildContext context) {
    final response = communication.getWidget(endpoint: endpoint);
    return switch ((response.statusCode, response.data)) {
      (InterModuleStatusCode.ok, final Widget widget) => widget,
      (InterModuleStatusCode.notFound, _) => notInstalled,
      _ => failed,
    };
  }
}

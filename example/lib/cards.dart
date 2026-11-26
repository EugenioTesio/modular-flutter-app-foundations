import 'package:flutter/material.dart';
import 'package:foundations/foundations.dart';

/// Cards as a micro app. It owns two endpoints:
///
/// * `/cards/v1/home-banner`, a banner other micro apps, such as Home, place
///   in their own screens. Which card it shows is Cards' own business:
///   callers send no parameters, and the banner loads the user's primary
///   card through Cards' own [ApiClient].
/// * `/cards/v1/details`, data about one card, for a caller that already
///   holds a card id, such as Transfers paying from a card the user chose.
///   Access depends on the session in Cards' own context.
final class CardsMicroApp implements MicroApp {
  /// Path of the backend call that returns the primary card's summary.
  static const primaryCardPath = '/cards/primary';

  /// Role a signed-in user needs to read card details.
  static const detailsReaderRole = 'cards.details.reader';

  late final MicroAppContext _context;

  /// Maps a session to Cards' access: signed out, signed in without
  /// [detailsReaderRole], or granted.
  static CardsAccess accessFor(SessionState session) => switch (session) {
    Unauthenticated() => CardsAccess.signedOut,
    Authenticated(:final identity)
        when (identity.customProperties['roles'] as List<Object?>? ?? const [])
            .contains(detailsReaderRole) =>
      CardsAccess.granted,
    Authenticated() => CardsAccess.forbidden,
  };

  @override
  String get id => 'cards';

  @override
  Set<String> get storedKeys => const {};

  @override
  Future<void> initialize(MicroAppContext context) async => _context = context;

  @override
  List<MicroAppRouteNode> get routes => const [];

  @override
  List<LocalizationsDelegate<Object?>> get localizationsDelegates => const [];

  @override
  List<DataEndpointProvider> get dataEndpoints => [
    CardsDetailsProvider(access: () => accessFor(_context.session.current)),
  ];

  @override
  List<WidgetEndpointProvider> get widgetEndpoints => [
    CardsHomeBannerProvider(apiClient: _context.apiClient),
  ];

  @override
  Future<void> dispose() async {}
}

/// Whether the current user may read card details.
enum CardsAccess {
  /// Signed in and allowed.
  granted,

  /// Not signed in.
  signedOut,

  /// Signed in, but without the needed role.
  forbidden,
}

/// Provides `/cards/v1/details`: the schema `{cardId, maskedNumber,
/// availableCredit}` for a card id.
class CardsDetailsProvider implements DataEndpointProvider {
  /// Creates the provider. [access] reports the current user's access.
  CardsDetailsProvider({required this.access});

  /// The current user's access to card details.
  final CardsAccess Function() access;

  static const _cards = {
    'card-123': {
      'cardId': 'card-123',
      'maskedNumber': '•••• 4821',
      'availableCredit': '2,500',
    },
  };

  @override
  InterModuleEndpoint get endpoint => const InterModuleEndpoint(
    url: '/cards/v1/details',
    requiredParameters: {'cardId'},
  );

  @override
  Future<InterModuleCommunicationResponse<Map<String, Object?>>> handle(
    Map<String, Object?> parameters,
  ) async {
    switch (access()) {
      case CardsAccess.signedOut:
        return const InterModuleCommunicationResponse.failure(
          statusCode: InterModuleStatusCode.badRequest,
          errorCode: InterModuleErrorCode.unauthenticated,
        );
      case CardsAccess.forbidden:
        return const InterModuleCommunicationResponse.failure(
          statusCode: InterModuleStatusCode.badRequest,
          errorCode: InterModuleErrorCode.forbidden,
        );
      case CardsAccess.granted:
        break;
    }

    final cardId = parameters['cardId'];
    if (cardId is! String || cardId.trim().isEmpty) {
      return const InterModuleCommunicationResponse.failure(
        statusCode: InterModuleStatusCode.badRequest,
        errorCode: 'invalid_card_id',
      );
    }
    // Simulates an unexpected failure inside Cards.
    if (cardId == 'boom') throw StateError('Cards storage is unavailable');
    final card = _cards[cardId];
    if (card == null) {
      return const InterModuleCommunicationResponse.failure(
        statusCode: InterModuleStatusCode.notFound,
        errorCode: 'card_not_found',
      );
    }
    return InterModuleCommunicationResponse.success(card);
  }
}

/// Provides `/cards/v1/home-banner`.
///
/// [build] returns the banner synchronously. The banner then loads its own
/// data and shows its own loading and error states, because errors after
/// `getWidget` belong to the providing micro app.
class CardsHomeBannerProvider implements WidgetEndpointProvider {
  /// Creates the provider over Cards' [apiClient].
  const CardsHomeBannerProvider({required this.apiClient});

  /// Cards' backend client.
  final ApiClient apiClient;

  @override
  InterModuleEndpoint get endpoint =>
      const InterModuleEndpoint(url: '/cards/v1/home-banner');

  @override
  InterModuleCommunicationResponse<Widget> build(
    Map<String, Object?> parameters,
  ) => InterModuleCommunicationResponse.success(
    CardsHomeBanner(apiClient: apiClient),
  );
}

/// The banner Cards hands out. It loads the primary card after it is placed.
class CardsHomeBanner extends StatefulWidget {
  /// Creates the banner.
  const CardsHomeBanner({super.key, required this.apiClient});

  /// Cards' backend client.
  final ApiClient apiClient;

  @override
  State<CardsHomeBanner> createState() => _CardsHomeBannerState();
}

class _CardsHomeBannerState extends State<CardsHomeBanner> {
  late final Future<Result<ApiResponse, ApiException>> _primary = widget
      .apiClient
      .get(CardsMicroApp.primaryCardPath);

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    return DsCard(
      child: FutureBuilder<Result<ApiResponse, ApiException>>(
        future: _primary,
        builder: (context, snapshot) {
          final body = switch (snapshot.data) {
            Ok(:final value) => value.body,
            _ => null,
          };
          if (snapshot.data is Err || (snapshot.hasData && body is! Map)) {
            return const DsInlineMessage(
              tone: DsMessageTone.error,
              message: 'Card details are unavailable right now.',
            );
          }
          final card = body as Map<String, Object?>?;
          return Row(
            children: [
              Icon(Icons.credit_card, color: colors.actionPrimary),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card == null
                          ? 'Your card'
                          : 'Card ${card['maskedNumber']}',
                      style: typography.bodyStrong.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    if (card == null)
                      const DsLoadingIndicator(
                        semanticsLabel: 'Loading card details',
                        size: 16,
                      )
                    else
                      Text(
                        'Available credit: ${card['availableCredit']}',
                        style: typography.body.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// @docImport '../capabilities/api_client.dart';
/// @docImport '../capabilities/app_logger.dart';
/// @docImport '../capabilities/crash_reporter.dart';
/// @docImport '../inter_module/inter_module_value.dart';
library;

import 'package:flutter/foundation.dart';

/// Value that describes the signed-in user, as micro apps see them.
///
/// Use this to greet the user or prefill a form. [email], [phoneNumber], and
/// [customProperties] are personal data: show them, but never write them to
/// [AppLogger], analytics, or crash reports. [toString] prints only [userId]
/// for that reason.
///
/// This is **not** a credential holder: it never contains tokens. Core keeps
/// them and [ApiClient] attaches them to backend calls itself.
///
/// Usage from a micro app:
/// ```dart
/// final greeting = switch (session.current) {
///   Authenticated(:final identity) => 'Hi ${identity.displayName ?? ''}',
///   Unauthenticated() => 'Welcome',
/// };
/// ```
@immutable
final class UserIdentity {
  /// Creates a user identity.
  ///
  /// Parameters:
  /// * [userId] - The opaque, stable identifier of the user.
  /// * [displayName] - Optional name to show in the interface.
  /// * [email] - Optional email address.
  /// * [phoneNumber] - Optional phone number.
  /// * [customProperties] - Optional other profile values; defaults to
  ///   empty.
  const UserIdentity({
    required this.userId,
    this.displayName,
    this.email,
    this.phoneNumber,
    this.customProperties = const {},
  });

  /// Opaque, stable identifier of the user.
  ///
  /// It is safe to use as a pseudonymous identifier, for example with
  /// [CrashReporter.setUserIdentifier].
  final String userId;

  /// Optional name to show in the interface.
  final String? displayName;

  /// Optional email address of the user.
  final String? email;

  /// Optional phone number of the user.
  final String? phoneNumber;

  /// Other profile values the identity provider supplies, such as an address
  /// or a customer segment.
  ///
  /// Values follow the payload rule (see [isInterModuleValue]), so any micro
  /// app can read them without importing another's types. It is compared key
  /// by key, with `==` for each value.
  final Map<String, Object?> customProperties;

  @override
  bool operator ==(Object other) =>
      other is UserIdentity &&
      other.userId == userId &&
      other.displayName == displayName &&
      other.email == email &&
      other.phoneNumber == phoneNumber &&
      mapEquals(other.customProperties, customProperties);

  @override
  int get hashCode => Object.hash(
    userId,
    displayName,
    email,
    phoneNumber,
    Object.hashAllUnordered(
      customProperties.entries.map(
        (entry) => Object.hash(entry.key, entry.value),
      ),
    ),
  );

  /// Returns a description that shows only [userId], so printing an identity
  /// never leaks personal data.
  @override
  String toString() => 'UserIdentity($userId)';
}

/// State of the user's session: [Authenticated] or [Unauthenticated], never
/// `null`.
///
/// Use this in a `switch` to adapt the interface to whether a user is signed
/// in; the class is `sealed`, so the switch is checked for exhaustiveness.
///
/// Built-in: Core moves the session between states, and each transition is
/// emitted on [SessionContext.changes]:
///
/// ```text
/// Unauthenticated ──sign-in──► Authenticated(A)
/// Authenticated(A) ──sign-out / expiry──► Unauthenticated
/// Authenticated(A) ──user switch──► Authenticated(B)
/// ```
@immutable
sealed class SessionState {
  const SessionState();
}

/// Session state in which a user is signed in.
///
/// This is **not** a token holder: it carries no session, access, or refresh
/// tokens. Core keeps them and [ApiClient] attaches them, so no micro app can
/// log or leak them.
final class Authenticated extends SessionState {
  /// Creates the signed-in state.
  ///
  /// Parameters:
  /// * [identity] - The user who is signed in.
  const Authenticated(this.identity);

  /// User who is signed in.
  final UserIdentity identity;

  @override
  bool operator ==(Object other) =>
      other is Authenticated && other.identity == identity;

  @override
  int get hashCode => Object.hash(Authenticated, identity);

  @override
  String toString() => 'Authenticated($identity)';
}

/// Session state in which no user is signed in.
///
/// Built-in: routes that require authentication send the user to sign-in
/// while the session is in this state.
final class Unauthenticated extends SessionState {
  /// Creates the signed-out state.
  const Unauthenticated();

  @override
  bool operator ==(Object other) => other is Unauthenticated;

  @override
  int get hashCode => (Unauthenticated).hashCode;

  @override
  String toString() => 'Unauthenticated()';
}

/// Contract that exposes the current user's session, read-only.
///
/// Use this to read who is signed in with [current], and to react to
/// sign-in, sign-out, expiry, or a user switch by listening to [changes].
///
/// This is **not** writable by micro apps: only Core changes the session.
///
/// Built-in: Core implements it from the application's authentication and
/// gives the same instance to every micro app through its context.
///
/// Usage from a micro app:
/// ```dart
/// final subscription = session.changes.listen((state) {
///   if (state is Unauthenticated) clearCachedAccounts();
/// });
/// ```
abstract interface class SessionContext {
  /// Session state right now, never `null`.
  SessionState get current;

  /// Broadcast stream of the new state on every sign-in, sign-out, session
  /// expiry, and user switch.
  ///
  /// It does not replay [current]: read [current] first, then listen.
  Stream<SessionState> get changes;
}

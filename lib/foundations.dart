/// Shared contracts for the modular Flutter app.
///
/// Micro apps, Core, and hosts import this library only. It provides:
///
/// * the inter-module communication contract, so micro apps exchange data and
///   UI without importing each other;
/// * application-owned capability abstractions (API client, analytics, crash
///   reporting, logging, feature flags, storage, navigation, session, and
///   permissions);
/// * the micro app and route contracts that hosts integrate;
/// * the unified design system and the `switchable_state` contract,
///   re-exported unchanged.
///
/// Testing support (the conformance check) lives in
/// `package:foundations/testing.dart`.
library;

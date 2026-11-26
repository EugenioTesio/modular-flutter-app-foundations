/// Environment an application build targets.
enum AppInfoEnvironment {
  /// Local and developer builds.
  development,

  /// Pre-release builds that talk to staging services.
  staging,

  /// Builds that reach end users.
  production,
}

/// Contract that exposes the facts about the running application.
///
/// Use this to show the version, tag a support request, or change behavior
/// outside production, without depending on a vendor package.
///
/// Built-in: Core implements it from the platform's package information and
/// gives it to each micro app through its context.
///
/// Usage from a micro app:
/// ```dart
/// Text('${appInfo.appName} ${appInfo.version} (${appInfo.buildNumber})');
///
/// if (appInfo.environment != AppInfoEnvironment.production) {
///   showDebugBanner();
/// }
/// ```
abstract interface class AppInfo {
  /// Display name of the application, never empty.
  String get appName;

  /// Semantic version of the application, such as `1.4.0`.
  String get version;

  /// Build number of the application, such as `42`, never empty.
  String get buildNumber;

  /// Environment this build targets.
  AppInfoEnvironment get environment;
}

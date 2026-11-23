/// @docImport '../routing/app_navigator.dart';
/// @docImport '../capabilities/session_context.dart';
/// @docImport 'endpoint_provider.dart';
/// @docImport 'inter_module_endpoint.dart';
/// @docImport 'inter_module_response.dart';
library;

/// Check that tells whether [value] follows the inter-module payload rule.
///
/// Use this when a value crosses a micro app boundary and you need to be sure
/// the receiver can read it without importing the sender's types: the
/// [InterModuleEndpoint.parameters] of a call, the data a
/// [DataEndpointProvider] returns in an [InterModuleCommunicationResponse],
/// a navigation body or [RouteCompleted.result] exchanged with another micro
/// app's screen, or [UserIdentity.customProperties].
///
/// A value passes when it is `null`, a [bool], [num], or [String], a [List]
/// whose elements all pass, or a [Map] whose keys are all [String] and whose
/// values all pass. Any other value fails, including sets, other iterables,
/// dates, and custom objects, and so does a collection that contains itself.
///
/// This is **not** a serializer: it never converts a value. Convert dates to
/// ISO-8601 strings and models to maps before sending them.
///
/// Built-in: Core may assert the rule in debug builds on every provider
/// response, so a non-conforming payload fails fast during development.
///
/// Examples:
/// ```dart
/// isInterModuleValue({'id': 'a1', 'tags': ['main'], 'balance': 12.5}); // true
/// isInterModuleValue({'when': DateTime.now()}); // false: send an ISO string
/// isInterModuleValue({1: 'one'}); // false: keys must be strings
/// ```
bool isInterModuleValue(Object? value) => _conforms(value, <Object>{});

bool _conforms(Object? value, Set<Object> path) {
  if (value == null || value is bool || value is num || value is String) {
    return true;
  }
  if (value is! List && value is! Map) return false;
  // Identity check guards against self-referencing collections.
  if (path.any((seen) => identical(seen, value))) return false;
  path.add(value);
  final result = switch (value) {
    List() => value.every((element) => _conforms(element, path)),
    Map() => value.entries.every(
      (entry) => entry.key is String && _conforms(entry.value, path),
    ),
    _ => false,
  };
  path.remove(value);
  return result;
}

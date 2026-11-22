/// Whether [value] follows the inter-module payload rule.
///
/// A value passes when it is `null`, a [bool], [num], or [String], a [List]
/// whose elements all pass, or a [Map] whose keys are all [String] and whose
/// values all pass. Any other value — including sets, other iterables, dates,
/// and custom objects — fails, as does a collection that contains itself.
///
/// The rule applies to inter-module parameters and data, and to navigation
/// results. Providers must only return conforming values, and implementations
/// such as Core may assert it in debug builds.
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

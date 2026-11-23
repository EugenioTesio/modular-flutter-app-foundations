import '../common/result.dart';
import '../exceptions/storage_exception.dart';

/// Contract that stores one micro app's values by key.
///
/// Use this for small, non-sensitive values your micro app keeps between
/// sessions, such as the last tab the user opened. Values are opaque strings
/// that each micro app serializes itself. Use [SecureKeyValueStore] for
/// sensitive values.
///
/// This is **not** shared between micro apps: each one can touch only the
/// keys it declares in `MicroApp.storedKeys`. Any operation on another key
/// returns an [Err] holding a [StorageException] of type
/// [StorageExceptionType.undeclaredKey], and leaves the other micro app's
/// value untouched. Keys follow `<microAppId>.<key>`; declaring a key, not its
/// prefix, is what reserves it.
///
/// Built-in: Core gives each micro app its own instance, limited to its
/// declared keys.
///
/// Usage from a micro app:
/// ```dart
/// await store.write('accounts.last_tab', 'savings');
///
/// final lastTab = switch (await store.read('accounts.last_tab')) {
///   Ok(:final value) => value ?? 'checking',
///   Err() => 'checking',
/// };
/// ```
abstract interface class KeyValueStore {
  /// Reads the value stored under a key.
  ///
  /// Parameters:
  /// * [key] - One of the micro app's declared keys.
  ///
  /// Returns `Ok(null)` when no value is stored there.
  Future<Result<String?, StorageException>> read(String key);

  /// Stores a value under a key, replacing any earlier value.
  ///
  /// Parameters:
  /// * [key] - One of the micro app's declared keys.
  /// * [value] - The value to store, already serialized.
  Future<Result<void, StorageException>> write(String key, String value);

  /// Removes the value stored under a key.
  ///
  /// Parameters:
  /// * [key] - One of the micro app's declared keys.
  ///
  /// Removing a key that holds no value succeeds.
  Future<Result<void, StorageException>> delete(String key);

  /// Checks whether a value is stored under a key.
  ///
  /// Parameters:
  /// * [key] - One of the micro app's declared keys.
  Future<Result<bool, StorageException>> containsKey(String key);
}

/// Contract that stores one micro app's sensitive values by key, such as
/// device secrets.
///
/// Use this instead of [KeyValueStore] for any value that must be encrypted
/// at rest. It is limited to the same declared keys, and it can be used
/// wherever a [KeyValueStore] is expected, but not the other way round.
///
/// This is **not** where session tokens live: Core keeps them and the API
/// client attaches them.
///
/// Built-in: Core implements it on top of the platform's secure storage.
abstract interface class SecureKeyValueStore implements KeyValueStore {}

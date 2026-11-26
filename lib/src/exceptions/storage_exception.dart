/// @docImport '../micro_app/micro_app.dart';
/// @docImport '../capabilities/key_value_store.dart';
/// @docImport '../common/result.dart';
library;

import 'package:flutter/foundation.dart';

/// Category of a [StorageException].
///
/// Use this to tell a programming mistake ([undeclaredKey]) from a storage
/// failure the user may hit at runtime.
enum StorageExceptionType {
  /// The underlying storage could not be opened.
  unavailable,

  /// The value could not be read.
  readFailed,

  /// The value could not be written.
  writeFailed,

  /// The value could not be deleted.
  deleteFailed,

  /// The key is not one of the calling micro app's declared
  /// [MicroApp.storedKeys].
  ///
  /// Core limits each micro app's stores to the keys it declares, so one
  /// micro app can never read or overwrite another's values. Declare the key
  /// in [MicroApp.storedKeys] to fix it.
  undeclaredKey,
}

/// Exception that explains why a storage operation on [key] failed.
///
/// Use this to react to a failed [KeyValueStore] or [SecureKeyValueStore]
/// call by its [type].
///
/// This is **not** thrown: the stores return it inside an [Err].
///
/// Usage from a micro app:
/// ```dart
/// switch (await store.write('accounts.last_tab', 'savings')) {
///   case Ok():
///     break;
///   case Err(failure: StorageException(type: StorageExceptionType.undeclaredKey)):
///     assert(false, 'Declare accounts.last_tab in storedKeys');
///   case Err(:final failure):
///     logger.warning('Could not save the tab', error: failure);
/// }
/// ```
@immutable
final class StorageException implements Exception {
  /// Creates a storage exception.
  ///
  /// Parameters:
  /// * [type] - The category of the failure.
  /// * [key] - The key the operation was given.
  const StorageException({required this.type, required this.key});

  /// Category of the failure.
  final StorageExceptionType type;

  /// Key the operation was given.
  final String key;

  @override
  bool operator ==(Object other) =>
      other is StorageException && other.type == type && other.key == key;

  @override
  int get hashCode => Object.hash(type, key);

  @override
  String toString() => 'StorageException(${type.name}, key: $key)';
}

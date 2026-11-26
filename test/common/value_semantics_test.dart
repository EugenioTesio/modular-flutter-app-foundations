// Feature: Value semantics of the public value types: equal values share a
// hash code, and printing a value never leaks credentials or personal data.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';

/// One value type under test: a value, an equal copy built separately, and a
/// value that differs.
final class _EqualityCase {
  const _EqualityCase(this.name, this.value, this.equal, this.different);

  final String name;
  final Object value;
  final Object equal;
  final Object different;
}

/// Builds values at run time so equality is not just `const` identity.
abstract final class _Values {
  static String text(String value) => String.fromCharCodes(value.codeUnits);

  static List<_EqualityCase> get equalityCases => [
    _EqualityCase(
      'ApiResponse',
      ApiResponse(statusCode: 200, headers: {'etag': text('a')}),
      ApiResponse(statusCode: 200, headers: {'etag': text('a')}),
      ApiResponse(statusCode: 200, headers: {'etag': text('b')}),
    ),
    _EqualityCase(
      'Authenticated',
      Authenticated(UserIdentity(userId: text('u1'))),
      Authenticated(UserIdentity(userId: text('u1'))),
      Authenticated(UserIdentity(userId: text('u2'))),
    ),
    const _EqualityCase(
      'Unauthenticated',
      Unauthenticated(),
      Unauthenticated(),
      Authenticated(UserIdentity(userId: 'u1')),
    ),
    _EqualityCase(
      'StorageException',
      StorageException(type: StorageExceptionType.readFailed, key: text('k')),
      StorageException(type: StorageExceptionType.readFailed, key: text('k')),
      StorageException(type: StorageExceptionType.writeFailed, key: text('k')),
    ),
    _EqualityCase(
      'RouteNotFoundException',
      RouteNotFoundException(text('/a')),
      RouteNotFoundException(text('/a')),
      RouteNotFoundException(text('/b')),
    ),
    const _EqualityCase(
      'RouteCancelled',
      RouteCancelled(),
      RouteCancelled(),
      RouteCompleted({}),
    ),
    const _EqualityCase(
      'PhotosDevicePermission',
      PhotosDevicePermission(),
      PhotosDevicePermission(access: PhotosDevicePermissionAccess.readWrite),
      PhotosDevicePermission(access: PhotosDevicePermissionAccess.addOnly),
    ),
    const _EqualityCase(
      'StorageDevicePermission',
      StorageDevicePermission(),
      StorageDevicePermission(scope: StorageDevicePermissionScope.shared),
      StorageDevicePermission(scope: StorageDevicePermissionScope.manageAll),
    ),
    const _EqualityCase(
      'CalendarDevicePermission',
      CalendarDevicePermission(),
      CalendarDevicePermission(access: CalendarDevicePermissionAccess.full),
      CalendarDevicePermission(
        access: CalendarDevicePermissionAccess.writeOnly,
      ),
    ),
    const _EqualityCase(
      'SensorsDevicePermission',
      SensorsDevicePermission(),
      SensorsDevicePermission(access: SensorsDevicePermissionAccess.whileInUse),
      SensorsDevicePermission(access: SensorsDevicePermissionAccess.always),
    ),
    const _EqualityCase(
      'BluetoothDevicePermission',
      BluetoothDevicePermission(),
      BluetoothDevicePermission(
        access: BluetoothDevicePermissionAccess.connect,
      ),
      BluetoothDevicePermission(access: BluetoothDevicePermissionAccess.scan),
    ),
  ];

  static Widget screen(
    BuildContext context,
    Map<String, String> parameters,
    Map<String, Object> body,
  ) => const SizedBox();

  static Widget layout(BuildContext context, Widget child) => child;

  /// Values and the exact text they print as.
  static Map<Object, String> get printed => {
    const Ok<int, String>(1): 'Ok(1)',
    const Err<int, String>('no'): 'Err(no)',
    const RouteCompleted({'id': 'a1'}): 'RouteCompleted({id: a1})',
    const RouteCancelled(): 'RouteCancelled()',
    const RouteNotFoundException('/a'): 'RouteNotFoundException(/a)',
    const StorageException(type: StorageExceptionType.readFailed, key: 'k'):
        'StorageException(readFailed, key: k)',
    const DuplicateEndpointException(url: '/a/v1/b', type: EndpointType.data):
        'DuplicateEndpointException: "/a/v1/b" is already registered as a '
        'data endpoint.',
    const BoolFeatureFlag(key: 'transfers.instant', defaultValue: false):
        'BoolFeatureFlag(transfers.instant, defaultValue: false)',
    const CameraDevicePermission(): 'CameraDevicePermission()',
    const PhotosDevicePermission(): 'PhotosDevicePermission(readWrite)',
    const StorageDevicePermission(): 'StorageDevicePermission(shared)',
    const CalendarDevicePermission(): 'CalendarDevicePermission(full)',
    const SensorsDevicePermission(): 'SensorsDevicePermission(whileInUse)',
    const BluetoothDevicePermission(): 'BluetoothDevicePermission(connect)',
    const LocationDevicePermission():
        'LocationDevicePermission(whileInUse, precise, '
        'temporaryPrecisePurposeKey: null)',
    const Authenticated(UserIdentity(userId: 'u1', email: 'ana@example.com')):
        'Authenticated(UserIdentity(u1))',
    const Unauthenticated(): 'Unauthenticated()',
    const MicroAppRoute(path: '/accounts', builder: screen):
        'MicroAppRoute(/accounts)',
    const MicroAppRouteGroup(
      builder: layout,
      routes: [MicroAppRoute(path: '/a', builder: screen)],
    ): 'MicroAppRouteGroup(1 routes)',
  };
}

void main() {
  for (final equalityCase in _Values.equalityCases) {
    group('Given two ${equalityCase.name} values built separately', () {
      test('When they hold the same fields, '
          'Then they are equal and share a hash code', () {
        // Given
        final value = equalityCase.value;
        final equal = equalityCase.equal;

        // When
        final isEqual = value == equal;

        // Then
        expect(isEqual, isTrue);
        expect(value.hashCode, equal.hashCode);
      });

      test('When a field differs, Then they are not equal', () {
        // Given
        final value = equalityCase.value;
        final different = equalityCase.different;

        // When
        final isEqual = value == different;

        // Then
        expect(isEqual, isFalse);
      });
    });
  }

  group('Given the public value types', () {
    test('When each is printed, '
        'Then it describes itself without its sensitive values', () {
      for (final MapEntry(key: value, value: expected)
          in _Values.printed.entries) {
        // When
        final printed = value.toString();

        // Then
        expect(printed, expected, reason: '${value.runtimeType}');
      }
    });
  });

  group('Given values that carry credentials or personal data', () {
    const secrets = ['s3cret-token', 'ana@example.com', '4111111111111111'];

    final values = <Object>[
      const ApiRequest(
        method: ApiMethod.post,
        path: '/transfers',
        queryParams: {'email': 'ana@example.com'},
        headers: {'X-Api-Key': 's3cret-token'},
        body: {'cardNumber': '4111111111111111'},
      ),
      const ApiResponse(
        statusCode: 200,
        headers: {'set-cookie': 's3cret-token'},
        body: {'email': 'ana@example.com'},
      ),
      const ApiException(
        type: ApiExceptionType.clientError,
        statusCode: 422,
        body: {'cardNumber': '4111111111111111'},
      ),
      const InterModuleEndpoint(
        url: '/cards/v1/details',
        parameters: {'cardNumber': '4111111111111111'},
        requiredParameters: {'cardNumber'},
      ),
      const InterModuleCommunicationResponse<Map<String, Object?>>.success({
        'email': 'ana@example.com',
      }),
    ];

    test('When they are printed, '
        'Then no value appears, only names and statuses', () {
      for (final value in values) {
        // When
        final printed = value.toString();

        // Then
        for (final secret in secrets) {
          expect(printed, isNot(contains(secret)), reason: printed);
        }
      }
    });

    test('When a request is printed, '
        'Then it shows the method, path, and parameter and header names', () {
      // When
      final printed = values.first.toString();

      // Then
      expect(
        printed,
        'ApiRequest(post /transfers, queryParams: [email], '
        'headers: [X-Api-Key], body: present)',
      );
    });

    test('When a response or failure is printed, '
        'Then it shows the status and whether a body is present', () {
      // When
      final printed = values.skip(1).map((value) => '$value').toList();

      // Then
      expect(printed, [
        'ApiResponse(200, headers: [set-cookie], body: present)',
        'ApiException(clientError, statusCode: 422, body: present)',
        'InterModuleEndpoint(/cards/v1/details, parameters: [cardNumber], '
            'requiredParameters: {cardNumber}, traceName: null)',
        'InterModuleCommunicationResponse(200, errorCode: null, '
            'data: present)',
      ]);
    });
  });
}

// Feature: Capability value types (FR-019, FR-022, FR-024, FR-025;
// data-model.md UserIdentity.userId, UserIdentity.customProperties,
// DevicePermission, StorageException.type, AppInfo.environment).
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';

/// Matches every session state without a default branch.
String greet(SessionState state) => switch (state) {
  Authenticated(:final identity) => 'Hi ${identity.displayName ?? 'there'}',
  Unauthenticated() => 'Please sign in',
};

/// Matches every storage failure type without a default branch.
String explain(StorageExceptionType type) => switch (type) {
  StorageExceptionType.unavailable => 'storage unavailable',
  StorageExceptionType.readFailed => 'could not read',
  StorageExceptionType.writeFailed => 'could not write',
  StorageExceptionType.deleteFailed => 'could not delete',
  StorageExceptionType.undeclaredKey => 'key not declared',
};

/// Matches every environment without a default branch.
String label(AppInfoEnvironment environment) => switch (environment) {
  AppInfoEnvironment.development => 'DEV',
  AppInfoEnvironment.staging => 'STG',
  AppInfoEnvironment.production => '',
};

void main() {
  group('Given each session state', () {
    const states = <SessionState>[
      Authenticated(UserIdentity(userId: 'u1', displayName: 'Ana')),
      Authenticated(UserIdentity(userId: 'u2')),
      Unauthenticated(),
    ];

    test('When they are matched exhaustively, '
        'Then each lands in its own branch', () {
      // When
      final greetings = states.map(greet).toList();

      // Then
      expect(greetings, ['Hi Ana', 'Hi there', 'Please sign in']);
    });

    test('When equal states built separately are compared, '
        'Then they are equal', () {
      // When
      // ignore: prefer_const_constructors
      final authenticated = Authenticated(UserIdentity(userId: 'u1'));
      // ignore: prefer_const_constructors
      final unauthenticated = Unauthenticated();

      // Then
      expect(authenticated, const Authenticated(UserIdentity(userId: 'u1')));
      expect(unauthenticated, const Unauthenticated());
      expect(authenticated == const Unauthenticated(), isFalse);
    });
  });

  group('Given two identities', () {
    test('When they share a userId and displayName, '
        'Then they are equal and share a hash code', () {
      // Given
      // ignore: prefer_const_constructors
      final first = UserIdentity(userId: 'u1', displayName: 'Ana');
      const second = UserIdentity(userId: 'u1', displayName: 'Ana');

      // When
      final equal = first == second;

      // Then
      expect(equal, isTrue);
      expect(first.hashCode, second.hashCode);
    });

    test('When their userIds differ, Then they are not equal', () {
      // When
      final equal =
          const UserIdentity(userId: 'u1') == const UserIdentity(userId: 'u2');

      // Then
      expect(equal, isFalse);
    });
  });

  group('Given an identity with profile fields', () {
    const identity = UserIdentity(
      userId: 'u1',
      displayName: 'Ana',
      email: 'ana@example.com',
      phoneNumber: '+34 600 000 000',
      customProperties: {
        'segment': 'premium',
        'address': 'Calle Mayor 1, Madrid',
      },
    );

    test('When it is compared with an identity built separately, '
        'Then custom properties are compared by content, key by key', () {
      // Given
      final same = UserIdentity(
        userId: 'u1',
        displayName: 'Ana',
        email: 'ana@example.com',
        phoneNumber: '+34 600 000 000',
        customProperties: {
          'address': 'Calle Mayor 1, Madrid',
          'segment': 'premium',
        },
      );

      // When
      final equal = identity == same;

      // Then
      expect(equal, isTrue);
      expect(identity.hashCode, same.hashCode);
    });

    test('When it is printed, '
        'Then only the userId appears, never personal data', () {
      // When
      final printed = identity.toString();

      // Then
      expect(printed, 'UserIdentity(u1)');
    });
  });

  group('Given the device permissions', () {
    /// Matches every permission without a default branch, so adding a
    /// variant breaks compilation here, as it would in Core's mapping.
    String describePermission(DevicePermission permission) =>
        switch (permission) {
          CameraDevicePermission() => 'camera',
          MicrophoneDevicePermission() => 'microphone',
          PhotosDevicePermission(:final access) => 'photos:${access.name}',
          VideosDevicePermission() => 'videos',
          AudioFilesDevicePermission() => 'audio files',
          MediaLibraryDevicePermission() => 'media library',
          MediaLocationDevicePermission() => 'media location',
          StorageDevicePermission(:final scope) => 'storage:${scope.name}',
          ContactsDevicePermission() => 'contacts',
          CalendarDevicePermission(:final access) => 'calendar:${access.name}',
          RemindersDevicePermission() => 'reminders',
          SpeechRecognitionDevicePermission() => 'speech',
          AssistantDevicePermission() => 'assistant',
          LocationDevicePermission(:final access, :final accuracy) =>
            'location:${access.name}:${accuracy.name}',
          SensorsDevicePermission(:final access) => 'sensors:${access.name}',
          ActivityRecognitionDevicePermission() => 'activity',
          BluetoothDevicePermission(:final access) =>
            'bluetooth:${access.name}',
          NearbyWifiDevicesDevicePermission() => 'nearby wifi',
          LocalNetworkDevicePermission() => 'local network',
          NotificationsDevicePermission() => 'notifications',
          CriticalAlertsDevicePermission() => 'critical alerts',
          NotificationPolicyDevicePermission() => 'notification policy',
          PhoneDevicePermission() => 'phone',
          SmsDevicePermission() => 'sms',
          AppTrackingDevicePermission() => 'app tracking',
          BackgroundRefreshDevicePermission() => 'background refresh',
          IgnoreBatteryOptimizationsDevicePermission() => 'battery',
          ScheduleExactAlarmDevicePermission() => 'exact alarm',
          SystemAlertWindowDevicePermission() => 'system alert window',
          InstallPackagesDevicePermission() => 'install packages',
        };

    test('When the permissions with options are built with defaults, '
        'Then the defaults are the least intrusive access', () {
      // Given
      const permissions = <DevicePermission>[
        PhotosDevicePermission(),
        StorageDevicePermission(),
        CalendarDevicePermission(),
        LocationDevicePermission(),
        SensorsDevicePermission(),
        BluetoothDevicePermission(),
      ];

      // When
      final descriptions = permissions.map(describePermission).toList();

      // Then
      expect(descriptions, [
        'photos:readWrite',
        'storage:shared',
        'calendar:full',
        'location:whileInUse:precise',
        'sensors:whileInUse',
        'bluetooth:connect',
      ]);
    });

    test('When every simple permission is described, '
        'Then each lands in its own branch', () {
      // Given
      const permissions = <DevicePermission>[
        CameraDevicePermission(),
        MicrophoneDevicePermission(),
        VideosDevicePermission(),
        AudioFilesDevicePermission(),
        MediaLibraryDevicePermission(),
        MediaLocationDevicePermission(),
        ContactsDevicePermission(),
        RemindersDevicePermission(),
        SpeechRecognitionDevicePermission(),
        AssistantDevicePermission(),
        ActivityRecognitionDevicePermission(),
        NearbyWifiDevicesDevicePermission(),
        LocalNetworkDevicePermission(),
        NotificationsDevicePermission(),
        CriticalAlertsDevicePermission(),
        NotificationPolicyDevicePermission(),
        PhoneDevicePermission(),
        SmsDevicePermission(),
        AppTrackingDevicePermission(),
        BackgroundRefreshDevicePermission(),
        IgnoreBatteryOptimizationsDevicePermission(),
        ScheduleExactAlarmDevicePermission(),
        SystemAlertWindowDevicePermission(),
        InstallPackagesDevicePermission(),
      ];

      // When
      final descriptions = permissions.map(describePermission).toSet();

      // Then
      expect(descriptions, hasLength(permissions.length));
    });

    test('When permissions built separately are compared, '
        'Then they are equal only when their type and options match', () {
      // When
      // ignore: prefer_const_constructors
      final camera = CameraDevicePermission();
      // ignore: prefer_const_constructors
      final location = LocationDevicePermission(
        accuracy: LocationDevicePermissionAccuracy.approximate,
        temporaryPrecisePurposeKey: 'Navigation',
      );
      // ignore: prefer_const_constructors
      final bluetooth = BluetoothDevicePermission(
        access: BluetoothDevicePermissionAccess.scan,
      );

      // Then
      expect(camera, const CameraDevicePermission());
      expect(camera.hashCode, const CameraDevicePermission().hashCode);
      expect(camera == const MicrophoneDevicePermission(), isFalse);
      expect(
        location,
        const LocationDevicePermission(
          accuracy: LocationDevicePermissionAccuracy.approximate,
          temporaryPrecisePurposeKey: 'Navigation',
        ),
      );
      expect(location == const LocationDevicePermission(), isFalse);
      expect(
        bluetooth,
        const BluetoothDevicePermission(
          access: BluetoothDevicePermissionAccess.scan,
        ),
      );
      expect(bluetooth == const BluetoothDevicePermission(), isFalse);
    });

    test('When the statuses are listed, '
        'Then they cover the platform answers plus unsupported', () {
      // When
      final statuses = DevicePermissionStatus.values;

      // Then
      expect(statuses, [
        DevicePermissionStatus.granted,
        DevicePermissionStatus.limited,
        DevicePermissionStatus.provisional,
        DevicePermissionStatus.denied,
        DevicePermissionStatus.permanentlyDenied,
        DevicePermissionStatus.restricted,
        DevicePermissionStatus.unsupported,
      ]);
      expect(DevicePermissionServiceStatus.values, [
        DevicePermissionServiceStatus.enabled,
        DevicePermissionServiceStatus.disabled,
        DevicePermissionServiceStatus.notApplicable,
      ]);
    });
  });

  group('Given every storage failure type', () {
    test('When each is explained exhaustively, '
        'Then the five types, including undeclaredKey, are distinct', () {
      // When
      final explanations = StorageExceptionType.values.map(explain).toSet();

      // Then
      expect(StorageExceptionType.values, hasLength(5));
      expect(
        StorageExceptionType.values,
        contains(StorageExceptionType.undeclaredKey),
      );
      expect(explanations, hasLength(5));
    });

    test('When a failure is built for an undeclared key, '
        'Then it keeps the type and the key and compares by value', () {
      // Given
      // ignore: prefer_const_constructors
      final failure = StorageException(
        type: StorageExceptionType.undeclaredKey,
        key: 'transfers.draft',
      );

      // When
      final same =
          failure ==
          const StorageException(
            type: StorageExceptionType.undeclaredKey,
            key: 'transfers.draft',
          );

      // Then
      expect(same, isTrue);
      expect(failure.type, StorageExceptionType.undeclaredKey);
      expect(failure.key, 'transfers.draft');
    });
  });

  group('Given every application environment', () {
    test('When each is labelled exhaustively, '
        'Then development, staging, and production exist', () {
      // When
      final labels = AppInfoEnvironment.values.map(label).toList();

      // Then
      expect(AppInfoEnvironment.values, [
        AppInfoEnvironment.development,
        AppInfoEnvironment.staging,
        AppInfoEnvironment.production,
      ]);
      expect(labels, ['DEV', 'STG', '']);
    });
  });
}

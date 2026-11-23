import 'package:flutter/foundation.dart';

/// Permission for a device capability that the operating system asks the
/// user to allow.
///
/// Use this to name the permission you pass to [DevicePermissions.status],
/// [DevicePermissions.request], or [DevicePermissions.serviceStatus]. Pick
/// the variant for the capability; variants that need options carry them,
/// the way [LocationDevicePermission] carries its access and accuracy.
///
/// This is **not** a business entitlement, such as whether the user may make
/// a transfer: each micro app checks those through its own backend.
///
/// Built-in: the class is `sealed`, with one variant per permission, so Core
/// maps every variant onto its permission plugins (for example
/// `permission_handler`, plus `geolocator` for location) exhaustively. Some
/// permissions exist on only one platform, as each variant says; on the other
/// platform, [DevicePermissions.status] and [DevicePermissions.request] return
/// [DevicePermissionStatus.unsupported].
///
/// Usage from a micro app:
/// ```dart
/// const camera = CameraDevicePermission();
/// const backgroundLocation = LocationDevicePermission(
///   access: LocationDevicePermissionAccess.always,
///   accuracy: LocationDevicePermissionAccuracy.approximate,
/// );
/// ```
@immutable
sealed class DevicePermission {
  const DevicePermission();

  @override
  bool operator ==(Object other) => other.runtimeType == runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => '$runtimeType()';
}

// ---------------------------------------------------------------------------
// Camera, microphone, and media
// ---------------------------------------------------------------------------

/// Permission to take photos and record video with the camera.
final class CameraDevicePermission extends DevicePermission {
  /// Creates a camera permission.
  const CameraDevicePermission();
}

/// Permission to record audio with the microphone.
final class MicrophoneDevicePermission extends DevicePermission {
  /// Creates a microphone permission.
  const MicrophoneDevicePermission();
}

/// Access a [PhotosDevicePermission] asks for.
enum PhotosDevicePermissionAccess {
  /// Reading and adding photos.
  readWrite,

  /// Only adding photos, without reading the library (iOS only; elsewhere it
  /// is treated as [readWrite]).
  addOnly,
}

/// Permission to use the photo library (on Android 13+, the device's
/// images).
final class PhotosDevicePermission extends DevicePermission {
  /// Creates a photo-library permission.
  ///
  /// Parameters:
  /// * [access] - Optional access to ask for; defaults to
  ///   [PhotosDevicePermissionAccess.readWrite].
  const PhotosDevicePermission({
    this.access = PhotosDevicePermissionAccess.readWrite,
  });

  /// Access the permission asks for.
  final PhotosDevicePermissionAccess access;

  @override
  bool operator ==(Object other) =>
      other is PhotosDevicePermission && other.access == access;

  @override
  int get hashCode => Object.hash(PhotosDevicePermission, access);

  @override
  String toString() => 'PhotosDevicePermission(${access.name})';
}

/// Permission to read the device's video files (Android 13+).
///
/// On iOS, videos belong to [PhotosDevicePermission].
final class VideosDevicePermission extends DevicePermission {
  /// Creates a videos permission.
  const VideosDevicePermission();
}

/// Permission to read the device's audio files (Android 13+).
final class AudioFilesDevicePermission extends DevicePermission {
  /// Creates an audio-files permission.
  const AudioFilesDevicePermission();
}

/// Permission to read the music and media library (iOS only).
final class MediaLibraryDevicePermission extends DevicePermission {
  /// Creates a media-library permission.
  const MediaLibraryDevicePermission();
}

/// Permission to read where photos and videos were taken (Android only).
final class MediaLocationDevicePermission extends DevicePermission {
  /// Creates a media-location permission.
  const MediaLocationDevicePermission();
}

/// Part of the shared storage a [StorageDevicePermission] covers.
enum StorageDevicePermissionScope {
  /// Shared external storage. Always denied on Android 13+: use
  /// [PhotosDevicePermission], [VideosDevicePermission], or
  /// [AudioFilesDevicePermission] there.
  shared,

  /// Managing all files on the device (Android 11+ "all files access").
  manageAll,
}

/// Permission to use the device's shared storage (Android only).
final class StorageDevicePermission extends DevicePermission {
  /// Creates a storage permission.
  ///
  /// Parameters:
  /// * [scope] - Optional part of the storage to ask for; defaults to
  ///   [StorageDevicePermissionScope.shared].
  const StorageDevicePermission({
    this.scope = StorageDevicePermissionScope.shared,
  });

  /// Part of the storage the permission covers.
  final StorageDevicePermissionScope scope;

  @override
  bool operator ==(Object other) =>
      other is StorageDevicePermission && other.scope == scope;

  @override
  int get hashCode => Object.hash(StorageDevicePermission, scope);

  @override
  String toString() => 'StorageDevicePermission(${scope.name})';
}

// ---------------------------------------------------------------------------
// Personal information
// ---------------------------------------------------------------------------

/// Permission to read the address book.
final class ContactsDevicePermission extends DevicePermission {
  /// Creates a contacts permission.
  const ContactsDevicePermission();
}

/// Access a [CalendarDevicePermission] asks for.
enum CalendarDevicePermissionAccess {
  /// Reading and writing events.
  full,

  /// Only adding events, without reading the calendar.
  writeOnly,
}

/// Permission to use the calendar.
final class CalendarDevicePermission extends DevicePermission {
  /// Creates a calendar permission.
  ///
  /// Parameters:
  /// * [access] - Optional access to ask for; defaults to
  ///   [CalendarDevicePermissionAccess.full].
  const CalendarDevicePermission({
    this.access = CalendarDevicePermissionAccess.full,
  });

  /// Access the permission asks for.
  final CalendarDevicePermissionAccess access;

  @override
  bool operator ==(Object other) =>
      other is CalendarDevicePermission && other.access == access;

  @override
  int get hashCode => Object.hash(CalendarDevicePermission, access);

  @override
  String toString() => 'CalendarDevicePermission(${access.name})';
}

/// Permission to read and write the reminders list (iOS only).
final class RemindersDevicePermission extends DevicePermission {
  /// Creates a reminders permission.
  const RemindersDevicePermission();
}

/// Permission to use speech recognition.
final class SpeechRecognitionDevicePermission extends DevicePermission {
  /// Creates a speech-recognition permission.
  const SpeechRecognitionDevicePermission();
}

/// Permission to integrate with the voice assistant, such as SiriKit (iOS
/// only).
final class AssistantDevicePermission extends DevicePermission {
  /// Creates an assistant permission.
  const AssistantDevicePermission();
}

// ---------------------------------------------------------------------------
// Location and motion
// ---------------------------------------------------------------------------

/// Time window in which a [LocationDevicePermission] lets the application
/// read the device's location.
enum LocationDevicePermissionAccess {
  /// Only while the application is in use.
  whileInUse,

  /// Also while the application runs in the background. The platforms grant
  /// it only after [whileInUse], so Core requests [whileInUse] first.
  always,
}

/// Precision of the location a [LocationDevicePermission] lets the
/// application read.
enum LocationDevicePermissionAccuracy {
  /// The exact location.
  precise,

  /// An approximate location, such as the neighbourhood.
  approximate,
}

/// Permission to read the device's location, with the access and accuracy
/// the feature needs.
///
/// Built-in: Core maps it onto `geolocator` and `permission_handler`. It
/// requests while-in-use access before `always`, as the platforms require.
final class LocationDevicePermission extends DevicePermission {
  /// Creates a location permission.
  ///
  /// Parameters:
  /// * [access] - Optional time window to ask for; defaults to
  ///   [LocationDevicePermissionAccess.whileInUse].
  /// * [accuracy] - Optional precision to ask for; defaults to
  ///   [LocationDevicePermissionAccuracy.precise].
  /// * [temporaryPrecisePurposeKey] - Optional iOS 14+ purpose key used to
  ///   ask for temporary precise location when only approximate location was
  ///   allowed.
  const LocationDevicePermission({
    this.access = LocationDevicePermissionAccess.whileInUse,
    this.accuracy = LocationDevicePermissionAccuracy.precise,
    this.temporaryPrecisePurposeKey,
  });

  /// Time window in which the location may be read.
  final LocationDevicePermissionAccess access;

  /// Precision of the location that may be read.
  final LocationDevicePermissionAccuracy accuracy;

  /// Optional purpose key, declared in the iOS `Info.plist` under
  /// `NSLocationTemporaryUsageDescriptionDictionary`, that explains why the
  /// feature needs precise location (iOS 14+).
  ///
  /// When the user allowed only approximate location and [accuracy] is
  /// [LocationDevicePermissionAccuracy.precise], Core asks for temporary
  /// precise location with this key. Ignored on other platforms.
  final String? temporaryPrecisePurposeKey;

  @override
  bool operator ==(Object other) =>
      other is LocationDevicePermission &&
      other.access == access &&
      other.accuracy == accuracy &&
      other.temporaryPrecisePurposeKey == temporaryPrecisePurposeKey;

  @override
  int get hashCode => Object.hash(
    LocationDevicePermission,
    access,
    accuracy,
    temporaryPrecisePurposeKey,
  );

  @override
  String toString() =>
      'LocationDevicePermission(${access.name}, ${accuracy.name}, '
      'temporaryPrecisePurposeKey: $temporaryPrecisePurposeKey)';
}

/// Time window in which a [SensorsDevicePermission] lets the application
/// read body sensors.
enum SensorsDevicePermissionAccess {
  /// Only while the application is in use.
  whileInUse,

  /// Also while the application runs in the background (Android 13+).
  always,
}

/// Permission to read body sensors, such as heart rate.
final class SensorsDevicePermission extends DevicePermission {
  /// Creates a sensors permission.
  ///
  /// Parameters:
  /// * [access] - Optional time window to ask for; defaults to
  ///   [SensorsDevicePermissionAccess.whileInUse].
  const SensorsDevicePermission({
    this.access = SensorsDevicePermissionAccess.whileInUse,
  });

  /// Time window in which the sensors may be read.
  final SensorsDevicePermissionAccess access;

  @override
  bool operator ==(Object other) =>
      other is SensorsDevicePermission && other.access == access;

  @override
  int get hashCode => Object.hash(SensorsDevicePermission, access);

  @override
  String toString() => 'SensorsDevicePermission(${access.name})';
}

/// Permission to recognize physical activity, such as walking or driving.
final class ActivityRecognitionDevicePermission extends DevicePermission {
  /// Creates an activity-recognition permission.
  const ActivityRecognitionDevicePermission();
}

// ---------------------------------------------------------------------------
// Connectivity
// ---------------------------------------------------------------------------

/// Bluetooth operation a [BluetoothDevicePermission] asks for.
///
/// Android 12+ grants each separately. iOS and older Android versions have a
/// single Bluetooth permission that covers all three.
enum BluetoothDevicePermissionAccess {
  /// Discovering nearby Bluetooth devices.
  scan,

  /// Connecting to paired Bluetooth devices.
  connect,

  /// Making this device discoverable to others.
  advertise,
}

/// Permission to use Bluetooth.
final class BluetoothDevicePermission extends DevicePermission {
  /// Creates a Bluetooth permission.
  ///
  /// Parameters:
  /// * [access] - Optional operation to ask for; defaults to
  ///   [BluetoothDevicePermissionAccess.connect].
  const BluetoothDevicePermission({
    this.access = BluetoothDevicePermissionAccess.connect,
  });

  /// Bluetooth operation the permission asks for.
  final BluetoothDevicePermissionAccess access;

  @override
  bool operator ==(Object other) =>
      other is BluetoothDevicePermission && other.access == access;

  @override
  int get hashCode => Object.hash(BluetoothDevicePermission, access);

  @override
  String toString() => 'BluetoothDevicePermission(${access.name})';
}

/// Permission to find and connect to nearby devices over Wi-Fi (Android
/// 13+).
final class NearbyWifiDevicesDevicePermission extends DevicePermission {
  /// Creates a nearby Wi-Fi devices permission.
  const NearbyWifiDevicesDevicePermission();
}

/// Permission to talk to devices on the local network (iOS 14+).
final class LocalNetworkDevicePermission extends DevicePermission {
  /// Creates a local-network permission.
  const LocalNetworkDevicePermission();
}

// ---------------------------------------------------------------------------
// Notifications
// ---------------------------------------------------------------------------

/// Permission to show notifications.
final class NotificationsDevicePermission extends DevicePermission {
  /// Creates a notifications permission.
  const NotificationsDevicePermission();
}

/// Permission to send critical alerts that bypass silent mode (iOS only).
///
/// It needs an Apple entitlement in addition to the user's consent.
final class CriticalAlertsDevicePermission extends DevicePermission {
  /// Creates a critical-alerts permission.
  const CriticalAlertsDevicePermission();
}

/// Permission to change the Do Not Disturb policy (Android only).
final class NotificationPolicyDevicePermission extends DevicePermission {
  /// Creates a notification-policy permission.
  const NotificationPolicyDevicePermission();
}

// ---------------------------------------------------------------------------
// Telephony
// ---------------------------------------------------------------------------

/// Permission to read the phone state and place calls (Android only).
final class PhoneDevicePermission extends DevicePermission {
  /// Creates a phone permission.
  const PhoneDevicePermission();
}

/// Permission to send and read SMS messages (Android only).
final class SmsDevicePermission extends DevicePermission {
  /// Creates a SMS permission.
  const SmsDevicePermission();
}

// ---------------------------------------------------------------------------
// Privacy and system
// ---------------------------------------------------------------------------

/// Permission to track the user across other companies' apps and websites
/// (iOS 14+ App Tracking Transparency).
final class AppTrackingDevicePermission extends DevicePermission {
  /// Creates an app-tracking permission.
  const AppTrackingDevicePermission();
}

/// Permission to refresh content in the background (iOS only).
///
/// This is **not** requestable: it can only be read, and
/// [DevicePermissions.request] returns the current status.
final class BackgroundRefreshDevicePermission extends DevicePermission {
  /// Creates a background-refresh permission.
  const BackgroundRefreshDevicePermission();
}

/// Permission to run without battery optimizations (Android only).
final class IgnoreBatteryOptimizationsDevicePermission
    extends DevicePermission {
  /// Creates an ignore-battery-optimizations permission.
  const IgnoreBatteryOptimizationsDevicePermission();
}

/// Permission to schedule exact alarms (Android 12+).
final class ScheduleExactAlarmDevicePermission extends DevicePermission {
  /// Creates an exact-alarm permission.
  const ScheduleExactAlarmDevicePermission();
}

/// Permission to draw over other applications (Android only).
final class SystemAlertWindowDevicePermission extends DevicePermission {
  /// Creates a system-alert-window permission.
  const SystemAlertWindowDevicePermission();
}

/// Permission to install other application packages (Android only).
final class InstallPackagesDevicePermission extends DevicePermission {
  /// Creates an install-packages permission.
  const InstallPackagesDevicePermission();
}

// ---------------------------------------------------------------------------
// Statuses and the contract
// ---------------------------------------------------------------------------

/// Status of one [DevicePermission]: the user's answer, or why there is
/// none.
enum DevicePermissionStatus {
  /// Allowed in full.
  granted,

  /// Allowed in part, such as a subset of the photo library (iOS 14+,
  /// Android 14+).
  limited,

  /// Allowed provisionally, such as quiet notifications (iOS 12+).
  provisional,

  /// Not allowed yet. Requesting it may show the system prompt.
  denied,

  /// Refused for good. Only the system settings can change it.
  ///
  /// On Android, only a request returns it: a status check reports [denied],
  /// because Android can't tell the two apart without asking.
  permanentlyDenied,

  /// Blocked by the device, such as parental controls. The user can't change
  /// it (iOS only).
  restricted,

  /// The current platform has no such permission. The feature decides
  /// whether it can work without it.
  unsupported,
}

/// Status of the system service behind a [DevicePermission], such as
/// location services.
///
/// Only location, Bluetooth, and phone permissions have one; for every other
/// permission it is [notApplicable].
enum DevicePermissionServiceStatus {
  /// The service is on.
  enabled,

  /// The service is off, such as location services switched off in the
  /// system settings. A granted permission is not enough to use it.
  disabled,

  /// The permission has no service to switch on.
  notApplicable,
}

/// Contract that checks and requests the device permissions the operating
/// system controls.
///
/// Use this before using a device capability, such as the camera or the
/// location: read the [status], [request] it when needed, check the
/// [serviceStatus] for location or Bluetooth, and send the user to
/// [openAppSettings] when the permission is permanently denied.
///
/// This is **not** for business entitlements, such as whether a user may
/// create a transfer: each micro app handles those through its own backend.
///
/// Built-in: Core implements it on top of the permission plugins the host
/// uses (for example `permission_handler`, plus `geolocator` for location),
/// so micro apps never import those plugins.
///
/// Usage from a micro app:
/// ```dart
/// const location = LocationDevicePermission();
///
/// switch (await permissions.request(location)) {
///   case DevicePermissionStatus.granted || DevicePermissionStatus.limited:
///     if (await permissions.serviceStatus(location) ==
///         DevicePermissionServiceStatus.disabled) {
///       askToTurnOnLocationServices();
///     } else {
///       showNearbyBranches();
///     }
///   case DevicePermissionStatus.permanentlyDenied:
///     await permissions.openAppSettings();
///   case _:
///     showBranchList();
/// }
/// ```
abstract interface class DevicePermissions {
  /// Returns the current status of a permission, without prompting the user.
  ///
  /// Parameters:
  /// * [permission] - The permission to check.
  ///
  /// On Android a permanently denied permission reports
  /// [DevicePermissionStatus.denied] here; only [request] reveals
  /// [DevicePermissionStatus.permanentlyDenied].
  Future<DevicePermissionStatus> status(DevicePermission permission);

  /// Asks the user for a permission when the system allows a prompt, and
  /// returns the resulting status.
  ///
  /// Parameters:
  /// * [permission] - The permission to request, with its options.
  ///
  /// When the status is already [DevicePermissionStatus.granted],
  /// [DevicePermissionStatus.permanentlyDenied],
  /// [DevicePermissionStatus.restricted], or
  /// [DevicePermissionStatus.unsupported], no prompt is shown.
  Future<DevicePermissionStatus> request(DevicePermission permission);

  /// Returns whether the system service behind a permission (location,
  /// Bluetooth, or phone) is switched on.
  ///
  /// Parameters:
  /// * [permission] - The permission whose service to check.
  ///
  /// A granted permission is not enough while its service is
  /// [DevicePermissionServiceStatus.disabled]. Every other permission returns
  /// [DevicePermissionServiceStatus.notApplicable].
  Future<DevicePermissionServiceStatus> serviceStatus(
    DevicePermission permission,
  );

  /// Opens the application's page in the system settings, so the user can
  /// change a permanently denied permission.
  ///
  /// Returns whether the settings page opened.
  Future<bool> openAppSettings();
}

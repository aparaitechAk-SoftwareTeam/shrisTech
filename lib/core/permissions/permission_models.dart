import 'package:permission_handler/permission_handler.dart';

/// Enumeration of permission categories managed by BBS GOLD.
enum AppPermissionType {
  notification,
  camera,
  media,
}

/// Unified representation of permission status across platforms.
enum AppPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  provisional,
  unknown;

  bool get isGranted => this == AppPermissionStatus.granted || this == AppPermissionStatus.limited;
  bool get isPermanentlyDenied => this == AppPermissionStatus.permanentlyDenied || this == AppPermissionStatus.restricted;
  bool get isDenied => this == AppPermissionStatus.denied;

  static AppPermissionStatus fromPermissionStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return AppPermissionStatus.granted;
      case PermissionStatus.denied:
        return AppPermissionStatus.denied;
      case PermissionStatus.permanentlyDenied:
        return AppPermissionStatus.permanentlyDenied;
      case PermissionStatus.restricted:
        return AppPermissionStatus.restricted;
      case PermissionStatus.limited:
        return AppPermissionStatus.limited;
      case PermissionStatus.provisional:
        return AppPermissionStatus.provisional;
    }
  }
}

/// Snapshot report of current OS permissions.
class PermissionStatusReport {
  final AppPermissionStatus notification;
  final AppPermissionStatus camera;
  final AppPermissionStatus media;
  final DateTime checkedAt;

  const PermissionStatusReport({
    required this.notification,
    required this.camera,
    required this.media,
    required this.checkedAt,
  });

  bool get allGranted =>
      notification.isGranted && camera.isGranted && media.isGranted;

  Map<String, dynamic> toMap() {
    return {
      'notification': notification.name,
      'camera': camera.name,
      'media': media.name,
      'checkedAt': checkedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'PermissionStatusReport(notification: ${notification.name}, camera: ${camera.name}, media: ${media.name}, checkedAt: $checkedAt)';
  }
}

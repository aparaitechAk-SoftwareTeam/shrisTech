import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../core/userdata.dart';
import '../repository/notification_repository.dart';

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final INotificationRepository _repository = NotificationRepository();
  bool _isTokenRefreshListenerRegistered = false;

  /// Sends the given FCM device token to the backend PUT /api/fcm-token endpoint.
  Future<bool> sendTokenToBackend(String fcmToken) async {
    final userUuid = UserData.instance.uuid;

    if (userUuid.isEmpty || fcmToken.isEmpty) {
      log('Skipping FCM token submission: User UUID or token missing (uuid: "$userUuid", token: "$fcmToken")');
      return false;
    }

    log('Submitting FCM Token to backend for user UUID: $userUuid');
    final result = await _repository.updateFcmToken(userUuid, fcmToken);
    log('FCM Token submission result for user $userUuid: $result');
    return result;
  }

  /// Requests notification permission, gets the current FCM token, sets presentation options,
  /// and sends it to the backend.
  Future<void> syncDeviceToken([String? token]) async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Set presentation options for iOS and Android
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (token != null && token.isNotEmpty) {
        await sendTokenToBackend(token);
        return;
      }

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        log('FCM permission denied by the user.');
        return;
      }

      final activeToken = await messaging.getToken();
      if (activeToken == null || activeToken.isEmpty) {
        log('FCM token was not generated.');
        return;
      }

      log('Active FCM Token obtained: $activeToken');
      await sendTokenToBackend(activeToken);

      if (!_isTokenRefreshListenerRegistered) {
        _isTokenRefreshListenerRegistered = true;
        messaging.onTokenRefresh.listen((refreshedToken) async {
          log('FCM Token refreshed: $refreshedToken');
          await sendTokenToBackend(refreshedToken);
        });
      }
    } catch (e) {
      log('FCM Sync error: $e');
    }
  }
}

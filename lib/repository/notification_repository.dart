import 'dart:developer';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/notification_models.dart';

abstract class INotificationRepository {
  Future<NotificationListResponse> fetchNotifications(String userId);
  Future<bool> markAsRead(String notificationId);
  Future<bool> markAllAsRead(String userId);
  Future<bool> updateFcmToken(String userId, String fcmToken);
}

class NotificationRepository implements INotificationRepository {
  NotificationRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<NotificationListResponse> fetchNotifications(String userId) async {
    try {
      log('user_id: $userId');
      final endpoint =
          '${ApiConstants.notificationsEndpoint}?user_id=${Uri.encodeComponent(userId)}';
      final json = await _apiClient.get(endpoint);
      return NotificationListResponse.fromJson(json);
    } catch (e) {
      log('Error fetching notifications: $e');
      rethrow;
    }
  }

  @override
  Future<bool> markAsRead(String notificationId) async {
    try {
      log('message: $notificationId');
      final endpoint = '/api/notifications/$notificationId/read';
      final json = await _apiClient.put(endpoint);
      return json['success'] == true || json['success'] == null;
    } catch (e) {
      log('Error marking notification $notificationId as read: $e');
      return false;
    }
  }

  @override
  Future<bool> markAllAsRead(String userId) async {
    try {
      final json = await _apiClient.put(
        ApiConstants.markAllNotificationsReadEndpoint,
        body: {'user_id': userId},
      );
      return json['success'] == true || json['success'] == null;
    } catch (e) {
      log('Error marking all notifications as read: $e');
      return false;
    }
  }

  @override
  Future<bool> updateFcmToken(String userId, String fcmToken) async {
    try {
      final json = await _apiClient.put(
        ApiConstants.fcmTokenEndpoint,
        body: {
          'user_id': userId,
          'id': userId,
          'fcm_token': fcmToken,
          'fcmToken': fcmToken,
          'token': fcmToken,
        },
      );
      log('FCM Token sync response: $json');
      return json['success'] == true || json['success'] == null;
    } catch (e) {
      log('Error updating FCM token: $e');
      return false;
    }
  }
}

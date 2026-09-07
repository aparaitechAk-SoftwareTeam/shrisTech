import 'package:flutter/foundation.dart';

import '../core/userdata.dart';
import '../models/notification_models.dart';
import '../repository/notification_repository.dart';

/// Singleton Service for Notification State management & live badge updates.
class NotificationService extends ValueNotifier<int> {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal() : super(0);

  final INotificationRepository _repository = NotificationRepository();

  List<NotificationModel> _cachedNotifications = [];
  List<NotificationModel> get cachedNotifications => _cachedNotifications;

  int get unreadCount => value;

  Future<NotificationListResponse> fetchNotifications() async {
    final isOwner = UserData.instance.role.trim().toLowerCase() == 'owner';
    final userId = isOwner
        ? '082ab0bb-0a20-47fc-8ed9-7a1daf9119cd'
        : UserData.instance.uuid;

    if (userId.isEmpty) {
      return NotificationListResponse(
        success: true,
        unreadCount: 0,
        notifications: [],
      );
    }

    try {
      final response = await _repository.fetchNotifications(userId);
      _cachedNotifications = response.notifications;
      value = response.unreadCount;
      return response;
    } catch (_) {
      return NotificationListResponse(
        success: false,
        unreadCount: value,
        notifications: _cachedNotifications,
      );
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    final success = await _repository.markAsRead(notificationId);
    if (success) {
      final idx = _cachedNotifications.indexWhere((n) => n.id == notificationId);
      if (idx != -1 && !_cachedNotifications[idx].isRead) {
        _cachedNotifications[idx] =
            _cachedNotifications[idx].copyWith(isRead: true);
        value = (value - 1).clamp(0, 999);
      }
    }
    return success;
  }

  Future<bool> markAllAsRead() async {
    final isOwner = UserData.instance.role.trim().toLowerCase() == 'owner';
    final userId = isOwner
        ? '082ab0bb-0a20-47fc-8ed9-7a1daf9119cd'
        : UserData.instance.uuid;
    if (userId.isEmpty) return false;

    final success = await _repository.markAllAsRead(userId);
    if (success) {
      _cachedNotifications =
          _cachedNotifications.map((n) => n.copyWith(isRead: true)).toList();
      value = 0;
    }
    return success;
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final String? referenceId;
  final bool isRead;
  final String createdAt;
  final String? roleTarget;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
    this.roleTarget,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] ?? json['notification_id'] ?? '').toString(),
      title: (json['title'] ?? 'Notification').toString(),
      message: (json['message'] ?? '').toString(),
      type: (json['type'] ?? json['notification_type'] ?? 'General').toString(),
      referenceId: json['reference_id']?.toString(),
      isRead: json['is_read'] == true || json['isRead'] == true,
      createdAt: (json['created_at'] ?? json['createdAt'] ?? '').toString(),
      roleTarget: json['role_target']?.toString(),
    );
  }

  NotificationModel copyWith({
    bool? isRead,
  }) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      referenceId: referenceId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      roleTarget: roleTarget,
    );
  }
}

class NotificationListResponse {
  final bool success;
  final int unreadCount;
  final List<NotificationModel> notifications;
  final String message;

  NotificationListResponse({
    required this.success,
    required this.unreadCount,
    required this.notifications,
    this.message = '',
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    final listRaw = json['notifications'] as List<dynamic>? ?? [];
    final notifications = listRaw
        .whereType<Map<String, dynamic>>()
        .map((e) => NotificationModel.fromJson(e))
        .toList();

    final computedUnread = notifications.where((n) => !n.isRead).length;

    return NotificationListResponse(
      success: json['success'] == true || json['success'] == null,
      unreadCount: json['unread_count'] != null
          ? int.tryParse(json['unread_count'].toString()) ?? computedUnread
          : computedUnread,
      notifications: notifications,
      message: (json['message'] ?? '').toString(),
    );
  }
}

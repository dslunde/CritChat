class NotificationEntity {
  final String id;
  final String userId; // recipient user ID
  final String senderId; // sender user ID
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>?
  data; // additional data like fellowship ID, friend request ID, etc.
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.senderId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  NotificationEntity copyWith({
    String? id,
    String? userId,
    String? senderId,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}

enum NotificationType {
  friendRequest,
  friendRequestAccepted,
  fellowshipInvite,
  fellowshipJoined,
  fellowshipMessage,
  directMessage,
  fellowshipCreated,
  systemMessage,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.friendRequest:
        return 'Friend Request';
      case NotificationType.friendRequestAccepted:
        return 'Friend Request Accepted';
      case NotificationType.fellowshipInvite:
        return 'Fellowship Invitation';
      case NotificationType.fellowshipJoined:
        return 'Fellowship Joined';
      case NotificationType.fellowshipMessage:
        return 'Fellowship Message';
      case NotificationType.directMessage:
        return 'Direct Message';
      case NotificationType.fellowshipCreated:
        return 'Fellowship Created';
      case NotificationType.systemMessage:
        return 'System Message';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.friendRequest:
        return '👋';
      case NotificationType.friendRequestAccepted:
        return '✅';
      case NotificationType.fellowshipInvite:
        return '⚔️';
      case NotificationType.fellowshipJoined:
        return '🎉';
      case NotificationType.fellowshipMessage:
        return '💬';
      case NotificationType.directMessage:
        return '📱';
      case NotificationType.fellowshipCreated:
        return '🏰';
      case NotificationType.systemMessage:
        return '🔔';
    }
  }
}

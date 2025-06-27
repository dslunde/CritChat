import 'package:critchat/features/notifications/domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.senderId,
    required super.type,
    required super.title,
    required super.message,
    super.data,
    required super.isRead,
    required super.isActioned,
    required super.createdAt,
    super.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json, String id) {
    return NotificationModel(
      id: id,
      userId: json['userId'] as String,
      senderId: json['senderId'] as String,
      type: NotificationType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => NotificationType.systemMessage,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool? ?? false,
      isActioned: json['isActioned'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'senderId': senderId,
      'type': type.name,
      'title': title,
      'message': message,
      'data': data,
      'isRead': isRead,
      'isActioned': isActioned,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  // Realtime Database methods (use milliseconds instead of ISO strings)
  factory NotificationModel.fromRealtimeJson(
    Map<dynamic, dynamic> json,
    String id,
  ) {
    return NotificationModel(
      id: id,
      userId: json['userId'] as String,
      senderId: json['senderId'] as String,
      type: NotificationType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => NotificationType.systemMessage,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'] as Map)
          : null,
      isRead: json['isRead'] as bool? ?? false,
      isActioned: json['isActioned'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      readAt: json['readAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['readAt'] as int)
          : null,
    );
  }

  Map<String, dynamic> toRealtimeJson() {
    return {
      'userId': userId,
      'senderId': senderId,
      'type': type.name,
      'title': title,
      'message': message,
      'data': data,
      'isRead': isRead,
      'isActioned': isActioned,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'readAt': readAt?.millisecondsSinceEpoch,
    };
  }

  factory NotificationModel.fromEntity(NotificationEntity entity) {
    return NotificationModel(
      id: entity.id,
      userId: entity.userId,
      senderId: entity.senderId,
      type: entity.type,
      title: entity.title,
      message: entity.message,
      data: entity.data,
      isRead: entity.isRead,
      isActioned: entity.isActioned,
      createdAt: entity.createdAt,
      readAt: entity.readAt,
    );
  }

  @override
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? senderId,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    bool? isActioned,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      isActioned: isActioned ?? this.isActioned,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  // Helper methods for creating specific notification types
  static NotificationModel createFriendRequest({
    required String id,
    required String userId,
    required String senderId,
    required String senderName,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      senderId: senderId,
      type: NotificationType.friendRequest,
      title: 'New Friend Request',
      message: '$senderName wants to be your friend',
      data: {'friendRequestId': id},
      isRead: false,
      isActioned: false,
      createdAt: DateTime.now(),
    );
  }

  static NotificationModel createFellowshipInvite({
    required String id,
    required String userId,
    required String senderId,
    required String senderName,
    required String fellowshipId,
    required String fellowshipName,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      senderId: senderId,
      type: NotificationType.fellowshipInvite,
      title: 'Fellowship Invitation',
      message: '$senderName invited you to join "$fellowshipName"',
      data: {'fellowshipId': fellowshipId, 'fellowshipName': fellowshipName},
      isRead: false,
      isActioned: false,
      createdAt: DateTime.now(),
    );
  }

  static NotificationModel createMessage({
    required String id,
    required String userId,
    required String senderId,
    required String senderName,
    required String messageText,
    required bool isDirect,
    String? fellowshipName,
    String? fellowshipId,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      senderId: senderId,
      type: isDirect
          ? NotificationType.directMessage
          : NotificationType.fellowshipMessage,
      title: isDirect ? 'New Message' : 'Fellowship Message',
      message: isDirect
          ? '$senderName: $messageText'
          : '$senderName in $fellowshipName: $messageText',
      data: isDirect
          ? {'messageText': messageText}
          : {
              'messageText': messageText,
              'fellowshipId': fellowshipId,
              'fellowshipName': fellowshipName,
            },
      isRead: false,
      isActioned: false,
      createdAt: DateTime.now(),
    );
  }
}

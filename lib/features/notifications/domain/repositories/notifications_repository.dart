import 'package:critchat/features/notifications/domain/entities/notification_entity.dart';

abstract class NotificationsRepository {
  Future<List<NotificationEntity>> getNotifications();
  Future<void> markAsRead(String notificationId);
  Future<void> markAsActioned(String notificationId);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String notificationId);
  Future<void> createNotification(NotificationEntity notification);
  Future<int> getUnreadCount();
  Stream<List<NotificationEntity>> watchNotifications();

  // Friend request specific actions
  Future<void> acceptFriendRequest(String notificationId, String senderId);
  Future<void> declineFriendRequest(String notificationId, String senderId);

  // Fellowship invite specific actions
  Future<void> acceptFellowshipInvite(
    String notificationId,
    String fellowshipId,
  );
  Future<void> declineFellowshipInvite(
    String notificationId,
    String fellowshipId,
  );
}

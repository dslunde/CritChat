import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_firestore_datasource.dart';
import '../models/notification_model.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsFirestoreDataSource _dataSource;

  NotificationsRepositoryImpl(this._dataSource);

  @override
  Future<List<NotificationEntity>> getNotifications() async {
    return await _dataSource.getNotifications();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _dataSource.markAsRead(notificationId);
  }

  @override
  Future<void> markAllAsRead() async {
    await _dataSource.markAllAsRead();
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await _dataSource.deleteNotification(notificationId);
  }

  @override
  Future<void> createNotification(NotificationEntity notification) async {
    final model = notification is NotificationModel
        ? notification
        : NotificationModel.fromEntity(notification);
    await _dataSource.createNotification(model);
  }

  @override
  Future<int> getUnreadCount() async {
    return await _dataSource.getUnreadCount();
  }

  @override
  Stream<List<NotificationEntity>> watchNotifications() {
    return _dataSource.watchNotifications();
  }

  @override
  Future<void> acceptFriendRequest(
    String notificationId,
    String senderId,
  ) async {
    await _dataSource.acceptFriendRequest(notificationId, senderId);
  }

  @override
  Future<void> declineFriendRequest(
    String notificationId,
    String senderId,
  ) async {
    await _dataSource.declineFriendRequest(notificationId, senderId);
  }

  @override
  Future<void> acceptFellowshipInvite(
    String notificationId,
    String fellowshipId,
  ) async {
    await _dataSource.acceptFellowshipInvite(notificationId, fellowshipId);
  }

  @override
  Future<void> declineFellowshipInvite(
    String notificationId,
    String fellowshipId,
  ) async {
    await _dataSource.declineFellowshipInvite(notificationId, fellowshipId);
  }
}

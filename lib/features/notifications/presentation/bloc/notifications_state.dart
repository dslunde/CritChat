import 'package:equatable/equatable.dart';
import '../../domain/entities/notification_entity.dart';

abstract class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationEntity> notifications;
  final int unreadCount;

  const NotificationsLoaded({
    required this.notifications,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [notifications, unreadCount];
}

class NotificationsEmpty extends NotificationsState {
  const NotificationsEmpty();
}

class NotificationsError extends NotificationsState {
  final String message;

  const NotificationsError(this.message);

  @override
  List<Object?> get props => [message];
}

class NotificationActionInProgress extends NotificationsState {
  final String notificationId;
  final String action;

  const NotificationActionInProgress({
    required this.notificationId,
    required this.action,
  });

  @override
  List<Object?> get props => [notificationId, action];
}

class NotificationActionSuccess extends NotificationsState {
  final String message;

  const NotificationActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class FriendRequestAccepted extends NotificationsState {
  final String friendId;

  const FriendRequestAccepted(this.friendId);

  @override
  List<Object?> get props => [friendId];
}

class FellowshipInviteAccepted extends NotificationsState {
  final String fellowshipId;

  const FellowshipInviteAccepted(this.fellowshipId);

  @override
  List<Object?> get props => [fellowshipId];
}

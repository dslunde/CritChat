import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationsEvent {
  const LoadNotifications();
}

class WatchNotifications extends NotificationsEvent {
  const WatchNotifications();
}

class MarkAsRead extends NotificationsEvent {
  final String notificationId;

  const MarkAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class MarkAllAsRead extends NotificationsEvent {
  const MarkAllAsRead();
}

class DeleteNotification extends NotificationsEvent {
  final String notificationId;

  const DeleteNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class AcceptFriendRequest extends NotificationsEvent {
  final String notificationId;
  final String senderId;

  const AcceptFriendRequest({
    required this.notificationId,
    required this.senderId,
  });

  @override
  List<Object?> get props => [notificationId, senderId];
}

class DeclineFriendRequest extends NotificationsEvent {
  final String notificationId;
  final String senderId;

  const DeclineFriendRequest({
    required this.notificationId,
    required this.senderId,
  });

  @override
  List<Object?> get props => [notificationId, senderId];
}

class AcceptFellowshipInvite extends NotificationsEvent {
  final String notificationId;
  final String fellowshipId;

  const AcceptFellowshipInvite({
    required this.notificationId,
    required this.fellowshipId,
  });

  @override
  List<Object?> get props => [notificationId, fellowshipId];
}

class DeclineFellowshipInvite extends NotificationsEvent {
  final String notificationId;
  final String fellowshipId;

  const DeclineFellowshipInvite({
    required this.notificationId,
    required this.fellowshipId,
  });

  @override
  List<Object?> get props => [notificationId, fellowshipId];
}

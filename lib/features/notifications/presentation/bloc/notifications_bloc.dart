import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../../domain/repositories/notifications_repository.dart';
import '../../domain/entities/notification_entity.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRepository _repository;
  StreamSubscription<List<NotificationEntity>>? _notificationsSubscription;

  NotificationsBloc({required NotificationsRepository repository})
    : _repository = repository,
      super(const NotificationsInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<WatchNotifications>(_onWatchNotifications);
    on<MarkAsRead>(_onMarkAsRead);
    on<MarkAllAsRead>(_onMarkAllAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<AcceptFriendRequest>(_onAcceptFriendRequest);
    on<DeclineFriendRequest>(_onDeclineFriendRequest);
    on<AcceptFellowshipInvite>(_onAcceptFellowshipInvite);
    on<DeclineFellowshipInvite>(_onDeclineFellowshipInvite);
  }

  @override
  Future<void> close() {
    _notificationsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      emit(const NotificationsLoading());

      final notifications = await _repository.getNotifications();
      final unreadCount = await _repository.getUnreadCount();

      if (notifications.isEmpty) {
        emit(const NotificationsEmpty());
      } else {
        emit(
          NotificationsLoaded(
            notifications: notifications,
            unreadCount: unreadCount,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      emit(NotificationsError('Failed to load notifications: ${e.toString()}'));
    }
  }

  Future<void> _onWatchNotifications(
    WatchNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await _notificationsSubscription?.cancel();

      await emit.forEach<List<NotificationEntity>>(
        _repository.watchNotifications(),
        onData: (notifications) {
          // Use add() to trigger a separate load event for async operations
          add(const LoadNotifications());

          if (notifications.isEmpty) {
            return const NotificationsEmpty();
          } else {
            // We'll get the exact count in LoadNotifications handler
            return NotificationsLoaded(
              notifications: notifications,
              unreadCount: notifications.where((n) => !n.isRead).length,
            );
          }
        },
        onError: (error, stackTrace) {
          return NotificationsError(
            'Real-time notifications error: ${error.toString()}',
          );
        },
      );
    } catch (e) {
      debugPrint('Error watching notifications: $e');
      emit(
        NotificationsError('Failed to watch notifications: ${e.toString()}'),
      );
    }
  }

  Future<void> _onMarkAsRead(
    MarkAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await _repository.markAsRead(event.notificationId);
      // Reload notifications to update UI
      add(const LoadNotifications());
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      emit(NotificationsError('Failed to mark as read: ${e.toString()}'));
    }
  }

  Future<void> _onMarkAllAsRead(
    MarkAllAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await _repository.markAllAsRead();
      emit(const NotificationActionSuccess('All notifications marked as read'));
      // Reload notifications to update UI
      add(const LoadNotifications());
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      emit(NotificationsError('Failed to mark all as read: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await _repository.deleteNotification(event.notificationId);
      emit(const NotificationActionSuccess('Notification deleted'));
      // Reload notifications to update UI
      add(const LoadNotifications());
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      emit(
        NotificationsError('Failed to delete notification: ${e.toString()}'),
      );
    }
  }

  Future<void> _onAcceptFriendRequest(
    AcceptFriendRequest event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      emit(
        NotificationActionInProgress(
          notificationId: event.notificationId,
          action: 'accepting',
        ),
      );

      await _repository.acceptFriendRequest(
        event.notificationId,
        event.senderId,
      );

      emit(FriendRequestAccepted(event.senderId));
      emit(const NotificationActionSuccess('Friend request accepted!'));

      // Reload notifications to update UI
      add(const LoadNotifications());
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      emit(
        NotificationsError('Failed to accept friend request: ${e.toString()}'),
      );
    }
  }

  Future<void> _onDeclineFriendRequest(
    DeclineFriendRequest event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      emit(
        NotificationActionInProgress(
          notificationId: event.notificationId,
          action: 'declining',
        ),
      );

      await _repository.declineFriendRequest(
        event.notificationId,
        event.senderId,
      );

      emit(const NotificationActionSuccess('Friend request declined'));

      // Reload notifications to update UI
      add(const LoadNotifications());
    } catch (e) {
      debugPrint('Error declining friend request: $e');
      emit(
        NotificationsError('Failed to decline friend request: ${e.toString()}'),
      );
    }
  }

  Future<void> _onAcceptFellowshipInvite(
    AcceptFellowshipInvite event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      emit(
        NotificationActionInProgress(
          notificationId: event.notificationId,
          action: 'accepting',
        ),
      );

      await _repository.acceptFellowshipInvite(
        event.notificationId,
        event.fellowshipId,
      );

      emit(FellowshipInviteAccepted(event.fellowshipId));
      emit(const NotificationActionSuccess('Fellowship invitation accepted!'));

      // Reload notifications to update UI
      add(const LoadNotifications());
    } catch (e) {
      debugPrint('Error accepting fellowship invite: $e');
      emit(
        NotificationsError(
          'Failed to accept fellowship invite: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onDeclineFellowshipInvite(
    DeclineFellowshipInvite event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      emit(
        NotificationActionInProgress(
          notificationId: event.notificationId,
          action: 'declining',
        ),
      );

      await _repository.declineFellowshipInvite(
        event.notificationId,
        event.fellowshipId,
      );

      emit(const NotificationActionSuccess('Fellowship invitation declined'));

      // Reload notifications to update UI
      add(const LoadNotifications());
    } catch (e) {
      debugPrint('Error declining fellowship invite: $e');
      emit(
        NotificationsError(
          'Failed to decline fellowship invite: ${e.toString()}',
        ),
      );
    }
  }
}

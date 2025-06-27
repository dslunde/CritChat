import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import 'package:critchat/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:critchat/features/notifications/domain/entities/notification_entity.dart';
import 'package:critchat/core/services/notification_indicator_service.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRepository _repository;
  final NotificationIndicatorService _indicatorService;
  StreamSubscription<List<NotificationEntity>>? _notificationsSubscription;

  NotificationsBloc({
    required NotificationsRepository repository,
    required NotificationIndicatorService indicatorService,
  }) : _repository = repository,
       _indicatorService = indicatorService,
       super(const NotificationsInitial()) {
    debugPrint('🔔 NotificationsBloc created and initialized');
    on<LoadNotifications>(_onLoadNotifications);
    on<WatchNotifications>((event, emit) async {
      debugPrint('🔔 WatchNotifications event received');
      await _onWatchNotifications(event, emit);
    });
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

      // Update the indicator service with the new unread count
      _indicatorService.updateUnreadNotifications(unreadCount);

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
      debugPrint('🔔 Starting to watch notifications...');
      await _notificationsSubscription?.cancel();

      // Initialize the indicator service now that auth is ready
      debugPrint('🔔 Initializing notification indicator service...');
      await _indicatorService.initialize();
      debugPrint('🔔 Notification indicator service initialized');

      await emit.forEach<List<NotificationEntity>>(
        _repository.watchNotifications(),
        onData: (notifications) {
          debugPrint('🔔 BLoC received ${notifications.length} notifications');

          // --- Categorization Logic ---
          int totalUnread = 0;
          int friendUnread = 0;
          int fellowshipUnread = 0;

          for (final notification in notifications) {
            if (!notification.isRead) {
              totalUnread++;
              switch (notification.type) {
                case NotificationType.directMessage:
                case NotificationType.friendRequest:
                case NotificationType.friendRequestAccepted:
                  friendUnread++;
                  break;
                case NotificationType.fellowshipMessage:
                case NotificationType.fellowshipInvite:
                case NotificationType.fellowshipJoined:
                case NotificationType.fellowshipCreated:
                  fellowshipUnread++;
                  break;
                default:
                  // Handles system messages and any future types
                  break;
              }
            }
          }

          debugPrint(
            '📊 Categorized Unread Counts: Total=$totalUnread, Friends=$friendUnread, Fellowships=$fellowshipUnread',
          );

          // Update all relevant indicator service streams
          _indicatorService.updateUnreadNotifications(totalUnread);
          _indicatorService.updateUnreadFriendMessages(friendUnread);
          _indicatorService.updateUnreadFellowshipMessages(fellowshipUnread);
          // --- End Categorization Logic ---

          if (notifications.isEmpty) {
            debugPrint('🔔 Emitting NotificationsEmpty');
            return const NotificationsEmpty();
          } else {
            debugPrint(
              '🔔 Emitting NotificationsLoaded with ${notifications.length} notifications and $totalUnread unread',
            );
            return NotificationsLoaded(
              notifications: notifications,
              unreadCount: totalUnread,
            );
          }
        },
        onError: (error, stackTrace) {
          debugPrint('🚨 BLoC watch error: $error');
          debugPrint('🚨 Stack trace: $stackTrace');
          return NotificationsError(
            'Real-time notifications error: ${error.toString()}',
          );
        },
      );
    } catch (e) {
      debugPrint('🚨 Error watching notifications: $e');
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

      // Mark as actioned to hide buttons
      await _repository.markAsActioned(event.notificationId);

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

      // Mark as actioned first to hide buttons
      await _repository.markAsActioned(event.notificationId);

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

      // Mark as actioned to hide buttons
      await _repository.markAsActioned(event.notificationId);

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

      // Mark as actioned first to hide buttons
      await _repository.markAsActioned(event.notificationId);

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

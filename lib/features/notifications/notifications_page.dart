import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:critchat/core/constants/app_colors.dart';
import 'presentation/bloc/notifications_bloc.dart';
import 'presentation/bloc/notifications_event.dart';
import 'presentation/bloc/notifications_state.dart';
import 'domain/entities/notification_entity.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Debug button to create test notification
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Create test notification',
            onPressed: () => _createTestNotification(context),
          ),
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsLoaded && state.unreadCount > 0) {
                return IconButton(
                  icon: const Icon(Icons.mark_email_read),
                  tooltip: 'Mark all as read',
                  onPressed: () {
                    context.read<NotificationsBloc>().add(
                      const MarkAllAsRead(),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<NotificationsBloc, NotificationsState>(
        listener: (context, state) {
          if (state is NotificationActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.successColor,
              ),
            );
          } else if (state is NotificationsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            );
          }

          if (state is NotificationsEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You\'re all caught up!',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is NotificationsLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<NotificationsBloc>().add(
                  const LoadNotifications(),
                );
              },
              color: AppColors.primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.notifications.length,
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return _NotificationCard(notification: notification);
                },
              ),
            );
          }

          if (state is NotificationsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<NotificationsBloc>().add(
                        const LoadNotifications(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          // Default state
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          );
        },
      ),
    );
  }

  void _createTestNotification(BuildContext context) async {
    try {
      // Import the dependencies we need
      final auth = FirebaseAuth.instance;
      final database = FirebaseDatabase.instance;

      final currentUser = auth.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
        return;
      }

      // Create a test notification for the current user
      final notificationId = database.ref('notifications').push().key!;
      final testNotification = {
        'userId': currentUser.uid,
        'senderId': 'test_sender',
        'type': 'systemMessage',
        'title': 'Test Notification',
        'message': 'This is a test notification created at ${DateTime.now()}',
        'data': null,
        'isRead': false,
        'isActioned': false,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      debugPrint('🧪 Creating test notification:');
      debugPrint('   ID: $notificationId');
      debugPrint('   Path: notifications/${currentUser.uid}/$notificationId');
      debugPrint('   Data: $testNotification');

      await database
          .ref('notifications/${currentUser.uid}/$notificationId')
          .set(testNotification);

      debugPrint('✅ Test notification created successfully');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification created!'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to create test notification: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create test notification: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationEntity notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: notification.isRead ? 0.6 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: notification.isRead
            ? AppColors.surfaceColor
            : AppColors.primaryColor.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: notification.isRead
                ? AppColors.dividerColor
                : AppColors.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: InkWell(
          onTap: () {
            if (!notification.isRead) {
              context.read<NotificationsBloc>().add(
                MarkAsRead(notification.id),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      notification.type.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.message,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),

                // Action buttons for friend requests and fellowship invites
                if (_needsActionButtons(notification.type) &&
                    !notification.isActioned) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _declineAction(context, notification),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.errorColor,
                        ),
                        child: const Text('Decline'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _acceptAction(context, notification),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Accept'),
                      ),
                    ],
                  ),
                ] else if (_needsActionButtons(notification.type) &&
                    notification.isActioned) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Responded',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],

                // Timestamp
                const SizedBox(height: 8),
                Text(
                  _formatTime(notification.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _needsActionButtons(NotificationType type) {
    return type == NotificationType.friendRequest ||
        type == NotificationType.fellowshipInvite;
  }

  void _acceptAction(BuildContext context, NotificationEntity notification) {
    switch (notification.type) {
      case NotificationType.friendRequest:
        context.read<NotificationsBloc>().add(
          AcceptFriendRequest(
            notificationId: notification.id,
            senderId: notification.senderId,
          ),
        );
        break;
      case NotificationType.fellowshipInvite:
        final fellowshipId = notification.data?['fellowshipId'] as String?;
        if (fellowshipId != null) {
          context.read<NotificationsBloc>().add(
            AcceptFellowshipInvite(
              notificationId: notification.id,
              fellowshipId: fellowshipId,
            ),
          );
        }
        break;
      default:
        break;
    }
  }

  void _declineAction(BuildContext context, NotificationEntity notification) {
    switch (notification.type) {
      case NotificationType.friendRequest:
        context.read<NotificationsBloc>().add(
          DeclineFriendRequest(
            notificationId: notification.id,
            senderId: notification.senderId,
          ),
        );
        break;
      case NotificationType.fellowshipInvite:
        final fellowshipId = notification.data?['fellowshipId'] as String?;
        if (fellowshipId != null) {
          context.read<NotificationsBloc>().add(
            DeclineFellowshipInvite(
              notificationId: notification.id,
              fellowshipId: fellowshipId,
            ),
          );
        }
        break;
      default:
        break;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

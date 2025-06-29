import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:critchat/features/notifications/data/models/notification_model.dart';
import 'package:critchat/features/notifications/domain/entities/notification_entity.dart';

abstract class NotificationsDataSource {
  Future<List<NotificationModel>> getNotifications();
  Future<void> markAsRead(String notificationId);
  Future<void> markAsActioned(String notificationId);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String notificationId);
  Future<void> createNotification(NotificationModel notification);
  Future<int> getUnreadCount();
  Stream<List<NotificationModel>> watchNotifications();
  Future<void> acceptFriendRequest(String notificationId, String senderId);
  Future<void> declineFriendRequest(String notificationId, String senderId);
  Future<void> acceptFellowshipInvite(
    String notificationId,
    String fellowshipId,
  );
  Future<void> declineFellowshipInvite(
    String notificationId,
    String fellowshipId,
  );
}

class NotificationsRealtimeDataSourceImpl implements NotificationsDataSource {
  final FirebaseDatabase _database;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore; // Still needed for user operations

  NotificationsRealtimeDataSourceImpl({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _database = database ?? FirebaseDatabase.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  @override
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final currentUserId = _currentUserId;
      if (currentUserId == null) return [];

      final snapshot = await _database
          .ref('notifications/$currentUserId')
          .orderByChild('createdAt')
          .get();

      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      final List<NotificationModel> notifications = [];
      data.forEach((key, value) {
        if (value is Map<dynamic, dynamic>) {
          notifications.add(NotificationModel.fromRealtimeJson(value, key));
        }
      });

      // Sort by creation date (newest first)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications.take(50).toList();
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      throw Exception('Failed to get notifications: $e');
    }
  }

  @override
  Stream<List<NotificationModel>> watchNotifications() {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      debugPrint('🚫 No current user for notification watching');
      return Stream.value([]);
    }

    final path = 'notifications/$currentUserId';
    debugPrint('👀 Starting to watch notifications at path: $path');

    return _database.ref(path).orderByChild('createdAt').onValue.map((event) {
      debugPrint('📡 Received notification data event');
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      debugPrint('📡 Raw data: $data');

      if (data == null) {
        debugPrint('📡 No notification data found');
        return <NotificationModel>[];
      }

      debugPrint('📡 Processing ${data.length} notifications');
      final List<NotificationModel> notifications = [];
      data.forEach((key, value) {
        debugPrint('📡 Processing notification $key: $value');
        if (value is Map<dynamic, dynamic>) {
          try {
            final notification = NotificationModel.fromRealtimeJson(value, key);
            notifications.add(notification);
            debugPrint(
              '✅ Successfully parsed notification: ${notification.title}',
            );
          } catch (e) {
            debugPrint('❌ Failed to parse notification $key: $e');
          }
        } else {
          debugPrint(
            '⚠️ Invalid notification data type for $key: ${value.runtimeType}',
          );
        }
      });

      // Sort by creation date (newest first)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final result = notifications.take(50).toList();
      debugPrint('📡 Returning ${result.length} notifications');
      return result;
    });
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      final currentUserId = _currentUserId;
      if (currentUserId == null) return;

      await _database
          .ref('notifications/$currentUserId/$notificationId')
          .update({
            'isRead': true,
            'readAt': DateTime.now().millisecondsSinceEpoch,
          });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> markAsActioned(String notificationId) async {
    try {
      final currentUserId = _currentUserId;
      if (currentUserId == null) return;

      await _database
          .ref('notifications/$currentUserId/$notificationId')
          .update({
            'isActioned': true,
            'isRead': true,
            'readAt': DateTime.now().millisecondsSinceEpoch,
          });
    } catch (e) {
      throw Exception('Failed to mark notification as actioned: $e');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      final currentUserId = _currentUserId;
      if (currentUserId == null) return;

      final snapshot = await _database
          .ref('notifications/$currentUserId')
          .orderByChild('isRead')
          .equalTo(false)
          .get();

      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;

      final Map<String, dynamic> updates = {};
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      data.forEach((notificationId, notificationData) {
        updates['notifications/$currentUserId/$notificationId/isRead'] = true;
        updates['notifications/$currentUserId/$notificationId/readAt'] =
            timestamp;
      });

      if (updates.isNotEmpty) {
        await _database.ref().update(updates);
      }
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      final currentUserId = _currentUserId;
      if (currentUserId == null) return;

      await _database
          .ref('notifications/$currentUserId/$notificationId')
          .remove();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  @override
  Future<void> createNotification(NotificationModel notification) async {
    try {
      final path = 'notifications/${notification.userId}/${notification.id}';
      final data = notification.toRealtimeJson();

      debugPrint('🔔 Creating notification:');
      debugPrint('   Path: $path');
      debugPrint('   Data: $data');
      debugPrint('   Current User: $_currentUserId');
      debugPrint('   Target User: ${notification.userId}');

      await _database.ref(path).set(data);

      debugPrint(
        '✅ Successfully created notification in Realtime DB: ${notification.id}',
      );

      // Verify it was created
      final verifySnapshot = await _database.ref(path).get();
      debugPrint('🔍 Verification - exists: ${verifySnapshot.exists}');
      if (verifySnapshot.exists) {
        debugPrint('🔍 Verification - data: ${verifySnapshot.value}');
      }
    } catch (e) {
      debugPrint('❌ Failed to create notification: $e');
      throw Exception('Failed to create notification: $e');
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final currentUserId = _currentUserId;
      if (currentUserId == null) return 0;

      final snapshot = await _database
          .ref('notifications/$currentUserId')
          .orderByChild('isRead')
          .equalTo(false)
          .get();

      final data = snapshot.value as Map<dynamic, dynamic>?;
      return data?.length ?? 0;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  @override
  Future<void> acceptFriendRequest(
    String notificationId,
    String senderId,
  ) async {
    try {
      final currentUserId = _currentUserId;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Use Firestore for user operations (friend relationships)
      final batch = _firestore.batch();

      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      final senderUserRef = _firestore.collection('users').doc(senderId);

      batch.update(currentUserRef, {
        'friends': FieldValue.arrayUnion([senderId]),
      });

      batch.update(senderUserRef, {
        'friends': FieldValue.arrayUnion([currentUserId]),
      });

      await batch.commit();

      // Mark notification as read in Realtime DB
      await markAsActioned(notificationId);

      // Create acceptance notification for sender
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      final currentUserData = currentUserDoc.data();
      final accepterName = currentUserData?['displayName'] ?? 'Someone';

      final acceptNotification = NotificationModel(
        id: _database.ref('notifications').push().key!,
        userId: senderId,
        senderId: currentUserId,
        type: NotificationType.friendRequestAccepted,
        title: 'Friend Request Accepted',
        message: '$accepterName accepted your friend request!',
        isRead: false,
        isActioned: false,
        createdAt: DateTime.now(),
      );

      await createNotification(acceptNotification);
    } catch (e) {
      throw Exception('Failed to accept friend request: $e');
    }
  }

  @override
  Future<void> declineFriendRequest(
    String notificationId,
    String senderId,
  ) async {
    try {
      // Simply delete the notification
      await deleteNotification(notificationId);
    } catch (e) {
      throw Exception('Failed to decline friend request: $e');
    }
  }

  @override
  Future<void> acceptFellowshipInvite(
    String notificationId,
    String fellowshipId,
  ) async {
    try {
      final currentUserId = _currentUserId;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Use Firestore for fellowship operations
      final batch = _firestore.batch();

      final fellowshipRef = _firestore
          .collection('fellowships')
          .doc(fellowshipId);
      final userRef = _firestore.collection('users').doc(currentUserId);

      batch.update(fellowshipRef, {
        'members': FieldValue.arrayUnion([currentUserId]),
      });

      batch.update(userRef, {
        'fellowships': FieldValue.arrayUnion([fellowshipId]),
      });

      await batch.commit();

      // Mark notification as actioned in Realtime DB
      await markAsActioned(notificationId);

      // Create join notification for fellowship members
      final fellowshipDoc = await _firestore
          .collection('fellowships')
          .doc(fellowshipId)
          .get();

      final fellowshipData = fellowshipDoc.data();
      final fellowshipName = fellowshipData?['name'] ?? 'Fellowship';
      final members = List<String>.from(fellowshipData?['members'] ?? []);

      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      final joinerName = currentUserDoc.data()?['displayName'] ?? 'Someone';

      // Notify other members (exclude the new joiner)
      for (final memberId in members) {
        if (memberId != currentUserId) {
          final joinNotification = NotificationModel(
            id: _database.ref('notifications').push().key!,
            userId: memberId,
            senderId: currentUserId,
            type: NotificationType.fellowshipJoined,
            title: 'New Fellowship Member',
            message: '$joinerName joined "$fellowshipName"',
            data: {
              'fellowshipId': fellowshipId,
              'fellowshipName': fellowshipName,
            },
            isRead: false,
            isActioned: false,
            createdAt: DateTime.now(),
          );

          await createNotification(joinNotification);
        }
      }
    } catch (e) {
      throw Exception('Failed to accept fellowship invite: $e');
    }
  }

  @override
  Future<void> declineFellowshipInvite(
    String notificationId,
    String fellowshipId,
  ) async {
    try {
      // Simply delete the notification
      await deleteNotification(notificationId);
    } catch (e) {
      throw Exception('Failed to decline fellowship invite: $e');
    }
  }
}

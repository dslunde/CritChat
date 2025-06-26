import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../../domain/entities/notification_entity.dart';

abstract class NotificationsFirestoreDataSource {
  Future<List<NotificationModel>> getNotifications();
  Future<void> markAsRead(String notificationId);
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

class NotificationsFirestoreDataSourceImpl
    implements NotificationsFirestoreDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  NotificationsFirestoreDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  @override
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final currentUserId = _currentUserId;
      if (currentUserId == null) return [];

      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs
          .map((doc) => NotificationModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get notifications: $e');
    }
  }

  @override
  Stream<List<NotificationModel>> watchNotifications() {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      final currentUserId = _currentUserId;
      if (currentUserId == null) return;

      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  @override
  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toJson());
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final currentUserId = _currentUserId;
      if (currentUserId == null) return 0;

      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
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

      final batch = _firestore.batch();

      // Add each other as friends (using proper method)
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      final senderUserRef = _firestore.collection('users').doc(senderId);

      batch.update(currentUserRef, {
        'friends': FieldValue.arrayUnion([senderId]),
      });

      batch.update(senderUserRef, {
        'friends': FieldValue.arrayUnion([currentUserId]),
      });

      // Mark notification as read and processed
      final notificationRef = _firestore
          .collection('notifications')
          .doc(notificationId);
      batch.update(notificationRef, {
        'isRead': true,
        'readAt': DateTime.now().toIso8601String(),
      });

      // Create acceptance notification for sender
      final senderUserDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      final senderUserData = senderUserDoc.data();
      final accepterName = senderUserData?['displayName'] ?? 'Someone';

      final acceptNotification = NotificationModel(
        id: _firestore.collection('notifications').doc().id,
        userId: senderId,
        senderId: currentUserId,
        type: NotificationType.friendRequestAccepted,
        title: 'Friend Request Accepted',
        message: '$accepterName accepted your friend request!',
        isRead: false,
        createdAt: DateTime.now(),
      );

      batch.set(
        _firestore.collection('notifications').doc(acceptNotification.id),
        acceptNotification.toJson(),
      );

      await batch.commit();
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
      // Simply mark the notification as read (delete it)
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

      final batch = _firestore.batch();

      // Add user to fellowship (using proper method)
      final fellowshipRef = _firestore
          .collection('fellowships')
          .doc(fellowshipId);
      batch.update(fellowshipRef, {
        'memberIds': FieldValue.arrayUnion([currentUserId]),
      });

      // Add fellowship to user's fellowships
      final userRef = _firestore.collection('users').doc(currentUserId);
      batch.update(userRef, {
        'fellowships': FieldValue.arrayUnion([fellowshipId]),
      });

      // Mark notification as read
      final notificationRef = _firestore
          .collection('notifications')
          .doc(notificationId);
      batch.update(notificationRef, {
        'isRead': true,
        'readAt': DateTime.now().toIso8601String(),
      });

      await batch.commit();
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
      // Simply mark the notification as read (delete it)
      await deleteNotification(notificationId);
    } catch (e) {
      throw Exception('Failed to decline fellowship invite: $e');
    }
  }
}

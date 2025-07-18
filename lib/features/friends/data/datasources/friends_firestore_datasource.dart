import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:critchat/features/friends/data/models/friend_model.dart';
import 'package:critchat/features/auth/data/models/user_model.dart';
import 'package:critchat/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:critchat/features/notifications/domain/entities/notification_entity.dart';

abstract class FriendsFirestoreDataSource {
  Future<List<FriendModel>> getFriends();
  Future<List<FriendModel>> searchUsers(String query);
  Future<void> sendFriendRequest(String friendId);
  Future<void> acceptFriendRequest(String friendId);
  Future<void> removeFriend(String friendId);
}

class FriendsFirestoreDataSourceImpl implements FriendsFirestoreDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseDatabase _database;
  final NotificationsRepository _notificationsRepository;

  FriendsFirestoreDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseDatabase? database,
    required NotificationsRepository notificationsRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _database = database ?? FirebaseDatabase.instance,
       _notificationsRepository = notificationsRepository;

  @override
  Future<List<FriendModel>> getFriends() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      // Get current user's document to fetch friends list
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (!userDoc.exists) return [];

      final userData = userDoc.data()!;
      final friendIds = List<String>.from(userData['friends'] ?? []);

      if (friendIds.isEmpty) return [];

      // Get friend user documents
      final List<FriendModel> friends = [];

      // Firestore limits 'in' queries to 10 items, so we batch them
      for (int i = 0; i < friendIds.length; i += 10) {
        final batch = friendIds.skip(i).take(10).toList();
        final querySnapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in querySnapshot.docs) {
          final userModel = UserModel.fromJson(doc.data(), doc.id);
          final friendModel = FriendModel.fromUserModel(userModel);
          friends.add(friendModel);
        }
      }

      return friends;
    } catch (e) {
      throw Exception('Failed to get friends: $e');
    }
  }

  @override
  Future<List<FriendModel>> searchUsers(String query) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      // Get current user's friends list to exclude them from search results
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final currentUserFriends = <String>{};
      if (currentUserDoc.exists) {
        final userData = currentUserDoc.data()!;
        final friendIds = List<String>.from(userData['friends'] ?? []);
        currentUserFriends.addAll(friendIds);
      }

      // Get all users and filter client-side for case insensitive search
      // This approach works better than trying to do case insensitive queries in Firestore
      final querySnapshot = await _firestore
          .collection('users')
          .where('displayName', isNotEqualTo: null)
          .limit(100) // Get a larger batch to filter from
          .get();

      final lowerQuery = query.toLowerCase();
      final List<FriendModel> users = [];

      for (final doc in querySnapshot.docs) {
        // Don't include current user or existing friends in search results
        if (doc.id != currentUser.uid && !currentUserFriends.contains(doc.id)) {
          final data = doc.data();
          final displayName = data['displayName'] as String?;

          // Case insensitive search
          if (displayName != null &&
              displayName.toLowerCase().contains(lowerQuery)) {
            final userModel = UserModel.fromJson(data, doc.id);
            final friendModel = FriendModel.fromUserModel(userModel);
            users.add(friendModel);
          }
        }
      }

      // Limit results to 20 after filtering
      return users.take(20).toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  @override
  Future<void> sendFriendRequest(String friendId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Get current user's display name for the notification
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final currentUserData = currentUserDoc.data();
      final currentUserName = currentUserData?['displayName'] ?? 'Someone';

      // Create friend request notification using NotificationsRepository
      final notification = NotificationEntity(
        id: _database.ref('notifications').push().key!,
        userId: friendId,
        senderId: currentUser.uid,
        type: NotificationType.friendRequest,
        title: 'Friend Request',
        message: '$currentUserName wants to be your friend',
        data: {'senderId': currentUser.uid},
        isRead: false,
        isActioned: false,
        createdAt: DateTime.now(),
      );

      await _notificationsRepository.createNotification(notification);
    } catch (e) {
      throw Exception('Failed to send friend request: $e');
    }
  }

  @override
  Future<void> acceptFriendRequest(String friendId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final batch = _firestore.batch();

      // Add each other as friends
      batch.update(_firestore.collection('users').doc(currentUser.uid), {
        'friends': FieldValue.arrayUnion([friendId]),
      });

      batch.update(_firestore.collection('users').doc(friendId), {
        'friends': FieldValue.arrayUnion([currentUser.uid]),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to accept friend request: $e');
    }
  }

  @override
  Future<void> removeFriend(String friendId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      await _firestore.collection('users').doc(currentUser.uid).update({
        'friends': FieldValue.arrayRemove([friendId]),
      });

      await _firestore.collection('users').doc(friendId).update({
        'friends': FieldValue.arrayRemove([currentUser.uid]),
      });
    } catch (e) {
      throw Exception('Failed to remove friend: $e');
    }
  }
}

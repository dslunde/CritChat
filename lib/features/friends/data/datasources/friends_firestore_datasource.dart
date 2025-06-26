import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:critchat/features/friends/data/models/friend_model.dart';
import 'package:critchat/features/auth/data/models/user_model.dart';

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

  FriendsFirestoreDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

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

      // Search by display name (case insensitive)
      final querySnapshot = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: '${query}z')
          .limit(20)
          .get();

      final List<FriendModel> users = [];
      for (final doc in querySnapshot.docs) {
        // Don't include current user in search results
        if (doc.id != currentUser.uid) {
          final userModel = UserModel.fromJson(doc.data(), doc.id);
          final friendModel = FriendModel.fromUserModel(userModel);
          users.add(friendModel);
        }
      }

      return users;
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

      // Create friend request notification (NOT auto-accepting)
      final notificationId = _firestore.collection('notifications').doc().id;

      // Only create the notification - do NOT add as friends yet
      await _firestore.collection('notifications').doc(notificationId).set({
        'userId': friendId,
        'senderId': currentUser.uid,
        'type': 'friendRequest', // Proper friend request type
        'title': 'Friend Request',
        'message': '$currentUserName wants to be your friend',
        'data': {'senderId': currentUser.uid},
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
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

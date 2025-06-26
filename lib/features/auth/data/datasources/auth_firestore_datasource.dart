import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:critchat/features/auth/data/models/user_model.dart';

abstract class AuthFirestoreDataSource {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> createUser(UserModel user);
  Future<UserModel> updateUser(UserModel user);
  Future<void> deleteUser(String userId);
  Future<UserModel?> getUserById(String userId);
  Future<List<UserModel>> getUsersByIds(List<String> userIds);
  Future<UserModel> addFriend(String userId, String friendId);
  Future<UserModel> removeFriend(String userId, String friendId);
  Future<UserModel> addFellowship(String userId, String fellowshipId);
  Future<UserModel> removeFellowship(String userId, String fellowshipId);
}

class AuthFirestoreDataSourceImpl implements AuthFirestoreDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AuthFirestoreDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (!doc.exists) return null;

      return UserModel.fromJson(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to get current user: $e');
    }
  }

  @override
  Future<UserModel> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toJson());
      return user;
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toJson());
      return user;
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  @override
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      return UserModel.fromJson(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to get user by ID: $e');
    }
  }

  @override
  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      final List<UserModel> users = [];

      // Firestore limits 'in' queries to 10 items, so we batch them
      for (int i = 0; i < userIds.length; i += 10) {
        final batch = userIds.skip(i).take(10).toList();
        final querySnapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in querySnapshot.docs) {
          users.add(UserModel.fromJson(doc.data(), doc.id));
        }
      }

      return users;
    } catch (e) {
      throw Exception('Failed to get users by IDs: $e');
    }
  }

  @override
  Future<UserModel> addFriend(String userId, String friendId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'friends': FieldValue.arrayUnion([friendId]),
      });

      // Also add the reverse friendship
      await _firestore.collection('users').doc(friendId).update({
        'friends': FieldValue.arrayUnion([userId]),
      });

      final updatedUser = await getUserById(userId);
      return updatedUser!;
    } catch (e) {
      throw Exception('Failed to add friend: $e');
    }
  }

  @override
  Future<UserModel> removeFriend(String userId, String friendId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'friends': FieldValue.arrayRemove([friendId]),
      });

      // Also remove the reverse friendship
      await _firestore.collection('users').doc(friendId).update({
        'friends': FieldValue.arrayRemove([userId]),
      });

      final updatedUser = await getUserById(userId);
      return updatedUser!;
    } catch (e) {
      throw Exception('Failed to remove friend: $e');
    }
  }

  @override
  Future<UserModel> addFellowship(String userId, String fellowshipId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fellowships': FieldValue.arrayUnion([fellowshipId]),
      });

      final updatedUser = await getUserById(userId);
      return updatedUser!;
    } catch (e) {
      throw Exception('Failed to add fellowship: $e');
    }
  }

  @override
  Future<UserModel> removeFellowship(String userId, String fellowshipId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fellowships': FieldValue.arrayRemove([fellowshipId]),
      });

      final updatedUser = await getUserById(userId);
      return updatedUser!;
    } catch (e) {
      throw Exception('Failed to remove fellowship: $e');
    }
  }
}

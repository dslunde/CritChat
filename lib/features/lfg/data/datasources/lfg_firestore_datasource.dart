import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:critchat/features/lfg/data/models/lfg_post_model.dart';
import 'package:flutter/foundation.dart';

abstract class LfgFirestoreDataSource {
  Future<List<LfgPostModel>> getActiveLfgPosts();
  Future<List<LfgPostModel>> getUserLfgPosts(String userId);
  Future<LfgPostModel> createLfgPost(LfgPostModel post);
  Future<LfgPostModel> updateLfgPost(LfgPostModel post);
  Future<void> expressInterest(String postId, String userId);
  Future<void> closeLfgPost(String postId);
  Future<LfgPostModel> refreshLfgPost(String postId);
  Future<void> deleteLfgPost(String postId);
  Stream<List<LfgPostModel>> getLfgPostsStream();
  Future<int> getUserActivePostCount(String userId);
  Future<LfgPostModel?> getLfgPostById(String postId);
}

class LfgFirestoreDataSourceImpl implements LfgFirestoreDataSource {
  final FirebaseFirestore _firestore;

  LfgFirestoreDataSourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _collection = 'lfgPosts';

  @override
  Future<List<LfgPostModel>> getActiveLfgPosts() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isClosed', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => LfgPostModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      // If index is missing or other Firestore errors, try a simpler query
      try {
        final querySnapshot = await _firestore
            .collection(_collection)
            .where('isClosed', isEqualTo: false)
            .get();

        final posts = querySnapshot.docs
            .map((doc) => LfgPostModel.fromJson(doc.data(), doc.id))
            .toList();
        
        // Sort in memory if we can't sort in Firestore
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return posts;
      } catch (fallbackError) {
        // If even the simple query fails, return empty list for graceful degradation
        debugPrint('⚠️ Firestore query failed, returning empty list: $fallbackError');
        return [];
      }
    }
  }

  @override
  Future<List<LfgPostModel>> getUserLfgPosts(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => LfgPostModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user LFG posts: $e');
    }
  }

  @override
  Future<LfgPostModel> createLfgPost(LfgPostModel post) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(post.toJson());
      final newPost = post.copyWith(id: docRef.id);

      // Update the document with the generated ID
      await docRef.update({'id': docRef.id});

      return newPost;
    } catch (e) {
      throw Exception('Failed to create LFG post: $e');
    }
  }

  @override
  Future<LfgPostModel> updateLfgPost(LfgPostModel post) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(post.id)
          .update(post.toJson());
      return post;
    } catch (e) {
      throw Exception('Failed to update LFG post: $e');
    }
  }

  @override
  Future<void> expressInterest(String postId, String userId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(postId)
          .update({
        'interestedUserIds': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      throw Exception('Failed to express interest: $e');
    }
  }

  @override
  Future<void> closeLfgPost(String postId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(postId)
          .update({'isClosed': true});
    } catch (e) {
      throw Exception('Failed to close LFG post: $e');
    }
  }

  @override
  Future<LfgPostModel> refreshLfgPost(String postId) async {
    try {
      final now = DateTime.now();
      await _firestore
          .collection(_collection)
          .doc(postId)
          .update({'lastRefreshed': now.toIso8601String()});
      
      final doc = await _firestore
          .collection(_collection)
          .doc(postId)
          .get();
      
      if (!doc.exists) {
        throw Exception('LFG post not found');
      }
      
      return LfgPostModel.fromJson(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to refresh LFG post: $e');
    }
  }

  @override
  Future<void> deleteLfgPost(String postId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(postId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete LFG post: $e');
    }
  }

  @override
  Stream<List<LfgPostModel>> getLfgPostsStream() {
    try {
      return _firestore
          .collection(_collection)
          .where('isClosed', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => LfgPostModel.fromJson(doc.data(), doc.id))
              .toList());
    } catch (e) {
      // Fallback to simpler stream if index is missing
      debugPrint('⚠️ Using fallback stream query due to: $e');
      return _firestore
          .collection(_collection)
          .where('isClosed', isEqualTo: false)
          .snapshots()
          .map((snapshot) {
            final posts = snapshot.docs
                .map((doc) => LfgPostModel.fromJson(doc.data(), doc.id))
                .toList();
            // Sort in memory
            posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return posts;
          });
    }
  }

  @override
  Future<int> getUserActivePostCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isClosed', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get user active post count: $e');
    }
  }

  @override
  Future<LfgPostModel?> getLfgPostById(String postId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(postId)
          .get();

      if (!doc.exists) return null;

      return LfgPostModel.fromJson(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to get LFG post by ID: $e');
    }
  }
} 
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:critchat/features/gamification/data/models/xp_model.dart';
import 'package:critchat/features/gamification/domain/entities/xp_entity.dart';
import 'package:critchat/features/auth/data/models/user_model.dart';

/// Data source interface for gamification operations
abstract class GamificationFirestoreDataSource {
  Future<XpModel> getUserXp(String userId);
  Future<XpModel> awardXp(
    String userId,
    XpRewardType rewardType, {
    Map<String, dynamic>? metadata,
  });
  Future<List<XpTransactionModel>> getUserXpHistory(
    String userId, {
    int limit = 50,
  });
  Stream<XpModel> getUserXpStream(String userId);
  Future<XpModel> initializeUserXp(String userId);
  Future<List<XpModel>> getLeaderboard({int limit = 10});
  Future<bool> hasReceivedReward(String userId, XpRewardType rewardType);
  Future<XpModel> batchAwardXp(
    String userId,
    List<XpRewardType> rewardTypes, {
    Map<String, dynamic>? metadata,
  });
}

/// Implementation of GamificationFirestoreDataSource using Firestore
class GamificationFirestoreDataSourceImpl
    implements GamificationFirestoreDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  GamificationFirestoreDataSourceImpl({
    required this.firestore,
    required this.auth,
  });

  @override
  Future<XpModel> getUserXp(String userId) async {
    try {
      final doc = await firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        debugPrint('User document not found for: $userId');
        // Return initial XP if user doesn't exist
        return XpModel.initial(userId);
      }

      final userData = doc.data()!;
      final userModel = UserModel.fromJson(userData, userId);

      // Convert user's totalXp to XpModel
      return _convertUserToXpModel(userModel);
    } catch (e) {
      debugPrint('Error getting user XP: $e');
      rethrow;
    }
  }

  /// Convert UserModel to XpModel using the user's totalXp field
  XpModel _convertUserToXpModel(UserModel user) {
    final currentLevel = XpEntity.calculateLevelFromXp(user.totalXp);
    final xpForCurrentLevel = XpEntity.calculateXpForLevel(currentLevel);
    final xpForNextLevel = XpEntity.calculateXpForLevel(currentLevel + 1);

    return XpModel(
      userId: user.id,
      totalXp: user.totalXp,
      currentLevel: currentLevel,
      xpForCurrentLevel: xpForCurrentLevel,
      xpForNextLevel: xpForNextLevel,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<XpModel> awardXp(
    String userId,
    XpRewardType rewardType, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final batch = firestore.batch();

      // Get current user XP
      final currentXp = await getUserXp(userId);

      // Calculate new total XP
      final newTotalXp = currentXp.totalXp + rewardType.xpAmount;

      // Update user document's totalXp field
      final userRef = firestore.collection('users').doc(userId);
      batch.update(userRef, {'totalXp': newTotalXp});

      // Create transaction record
      final transactionRef = firestore.collection('xp_transactions').doc();
      final transaction = XpTransactionModel.create(
        userId: userId,
        rewardType: rewardType,
        metadata: metadata,
      );
      batch.set(transactionRef, transaction.toFirestore());

      // Commit batch
      await batch.commit();

      // Return updated XP model with new total XP
      return _createXpModelWithTotalXp(userId, newTotalXp);
    } catch (e) {
      debugPrint('Error awarding XP: $e');
      rethrow;
    }
  }

  /// Create XpModel with specific total XP
  XpModel _createXpModelWithTotalXp(String userId, int totalXp) {
    final currentLevel = XpEntity.calculateLevelFromXp(totalXp);
    final xpForCurrentLevel = XpEntity.calculateXpForLevel(currentLevel);
    final xpForNextLevel = XpEntity.calculateXpForLevel(currentLevel + 1);

    return XpModel(
      userId: userId,
      totalXp: totalXp,
      currentLevel: currentLevel,
      xpForCurrentLevel: xpForCurrentLevel,
      xpForNextLevel: xpForNextLevel,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<List<XpTransactionModel>> getUserXpHistory(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await firestore
          .collection('xp_transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => XpTransactionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting user XP history: $e');
      rethrow;
    }
  }

  @override
  Stream<XpModel> getUserXpStream(String userId) {
    try {
      return firestore.collection('users').doc(userId).snapshots().map((doc) {
        if (!doc.exists || doc.data() == null) {
          // Return initial XP if document doesn't exist
          return XpModel.initial(userId);
        }

        final userData = doc.data()!;
        final userModel = UserModel.fromJson(userData, userId);
        return _convertUserToXpModel(userModel);
      });
    } catch (e) {
      debugPrint('Error getting user XP stream: $e');
      rethrow;
    }
  }

  @override
  Future<XpModel> initializeUserXp(String userId) async {
    try {
      // Check if user document exists
      final userDoc = await firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        // User exists, ensure totalXp field is set to 0 if it doesn't exist
        final userData = userDoc.data()!;
        if (!userData.containsKey('totalXp')) {
          await firestore.collection('users').doc(userId).update({
            'totalXp': 0,
          });
        }
      } else {
        debugPrint(
          'Warning: Trying to initialize XP for non-existent user: $userId',
        );
      }

      return XpModel.initial(userId);
    } catch (e) {
      debugPrint('Error initializing user XP: $e');
      rethrow;
    }
  }

  @override
  Future<List<XpModel>> getLeaderboard({int limit = 10}) async {
    try {
      final querySnapshot = await firestore
          .collection('users')
          .orderBy('totalXp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final userData = doc.data();
        final userModel = UserModel.fromJson(userData, doc.id);
        return _convertUserToXpModel(userModel);
      }).toList();
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasReceivedReward(String userId, XpRewardType rewardType) async {
    try {
      final querySnapshot = await firestore
          .collection('xp_transactions')
          .where('userId', isEqualTo: userId)
          .where('rewardType', isEqualTo: rewardType.name)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if reward received: $e');
      rethrow;
    }
  }

  @override
  Future<XpModel> batchAwardXp(
    String userId,
    List<XpRewardType> rewardTypes, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final batch = firestore.batch();

      // Get current user XP
      final currentXp = await getUserXp(userId);

      // Calculate total XP to award
      final totalXpToAward = rewardTypes.fold<int>(
        0,
        (total, type) => total + type.xpAmount,
      );
      final newTotalXp = currentXp.totalXp + totalXpToAward;

      // Update user document's totalXp field
      final userRef = firestore.collection('users').doc(userId);
      batch.update(userRef, {'totalXp': newTotalXp});

      // Create transaction records for each reward type
      for (final rewardType in rewardTypes) {
        final transactionRef = firestore.collection('xp_transactions').doc();
        final transaction = XpTransactionModel.create(
          userId: userId,
          rewardType: rewardType,
          metadata: metadata,
        );
        batch.set(transactionRef, transaction.toFirestore());
      }

      // Commit batch
      await batch.commit();

      return _createXpModelWithTotalXp(userId, newTotalXp);
    } catch (e) {
      debugPrint('Error batch awarding XP: $e');
      rethrow;
    }
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:critchat/features/gamification/data/models/xp_model.dart';
import 'package:critchat/features/gamification/domain/entities/xp_entity.dart';

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
      final doc = await firestore.collection('user_xp').doc(userId).get();

      if (!doc.exists) {
        // Initialize user XP if it doesn't exist
        return await initializeUserXp(userId);
      }

      return XpModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting user XP: $e');
      rethrow;
    }
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

      // Calculate new XP
      final newXp = currentXp.addXp(rewardType.xpAmount);

      // Update user XP document
      final userXpRef = firestore.collection('user_xp').doc(userId);
      batch.update(userXpRef, XpModel.fromEntity(newXp).toFirestore());

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

      return XpModel.fromEntity(newXp);
    } catch (e) {
      debugPrint('Error awarding XP: $e');
      rethrow;
    }
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
      return firestore.collection('user_xp').doc(userId).snapshots().map((doc) {
        if (!doc.exists) {
          // Return initial XP if document doesn't exist
          return XpModel.initial(userId);
        }
        return XpModel.fromFirestore(doc);
      });
    } catch (e) {
      debugPrint('Error getting user XP stream: $e');
      rethrow;
    }
  }

  @override
  Future<XpModel> initializeUserXp(String userId) async {
    try {
      final initialXp = XpModel.initial(userId);
      await firestore
          .collection('user_xp')
          .doc(userId)
          .set(initialXp.toFirestore());

      return initialXp;
    } catch (e) {
      debugPrint('Error initializing user XP: $e');
      rethrow;
    }
  }

  @override
  Future<List<XpModel>> getLeaderboard({int limit = 10}) async {
    try {
      final querySnapshot = await firestore
          .collection('user_xp')
          .orderBy('totalXp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => XpModel.fromFirestore(doc))
          .toList();
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
        (sum, type) => sum + type.xpAmount,
      );
      final newXp = currentXp.addXp(totalXpToAward);

      // Update user XP document
      final userXpRef = firestore.collection('user_xp').doc(userId);
      batch.update(userXpRef, XpModel.fromEntity(newXp).toFirestore());

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

      return XpModel.fromEntity(newXp);
    } catch (e) {
      debugPrint('Error batch awarding XP: $e');
      rethrow;
    }
  }
}

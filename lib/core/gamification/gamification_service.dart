import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:critchat/core/di/injection_container.dart';
import 'package:critchat/features/gamification/domain/entities/xp_entity.dart';
import 'package:critchat/features/gamification/domain/repositories/gamification_repository.dart';

/// Data class for level up information
class LevelUpData {
  final XpEntity updatedXp;
  final int previousLevel;
  final int xpGained;

  const LevelUpData({
    required this.updatedXp,
    required this.previousLevel,
    required this.xpGained,
  });
}

/// Core service for gamification functionality
/// This is the main interface other features should use to interact with XP system
class GamificationService {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  late final GamificationRepository _repository;
  late final FirebaseAuth _auth;

  // Level up tracking
  LevelUpData? _lastLevelUp;

  /// Initialize the service with dependencies
  void initialize() {
    _repository = sl<GamificationRepository>();
    _auth = sl<FirebaseAuth>();
  }

  /// Get and clear the last level up data (for showing level up dialog)
  LevelUpData? getAndClearLevelUp() {
    final levelUp = _lastLevelUp;
    _lastLevelUp = null;
    return levelUp;
  }

  /// Check if there's a pending level up to show
  bool get hasPendingLevelUp => _lastLevelUp != null;

  /// Award XP to the current user for a specific action
  /// Returns the updated XP entity, or null if user is not authenticated
  Future<XpEntity?> awardXp(
    XpRewardType rewardType, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('Cannot award XP: User not authenticated');
        return null;
      }

      // Get current XP data to check for level up
      final previousXp = await _repository.getUserXp(currentUser.uid);
      final previousLevel = previousXp.currentLevel;

      debugPrint(
        'Awarding ${rewardType.xpAmount} XP for ${rewardType.description}',
      );

      final updatedXp = await _repository.awardXp(
        currentUser.uid,
        rewardType,
        metadata: metadata,
      );

      debugPrint(
        'XP awarded successfully. Total XP: ${updatedXp.totalXp}, Level: ${updatedXp.currentLevel}',
      );

      // Check for level up
      if (updatedXp.currentLevel > previousLevel) {
        debugPrint(
          '🎉 LEVEL UP! User leveled up from $previousLevel to ${updatedXp.currentLevel}',
        );
        // Store level up data for UI to display
        _lastLevelUp = LevelUpData(
          updatedXp: updatedXp,
          previousLevel: previousLevel,
          xpGained: rewardType.xpAmount,
        );
      }

      return updatedXp;
    } catch (e) {
      debugPrint('Error awarding XP: $e');
      return null;
    }
  }

  /// Award XP to a specific user (admin function)
  Future<XpEntity?> awardXpToUser(
    String userId,
    XpRewardType rewardType, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint(
        'Awarding ${rewardType.xpAmount} XP to user $userId for ${rewardType.description}',
      );

      final updatedXp = await _repository.awardXp(
        userId,
        rewardType,
        metadata: metadata,
      );

      debugPrint(
        'XP awarded successfully to user $userId. Total XP: ${updatedXp.totalXp}, Level: ${updatedXp.currentLevel}',
      );

      return updatedXp;
    } catch (e) {
      debugPrint('Error awarding XP to user $userId: $e');
      return null;
    }
  }

  /// Award multiple XP rewards in a batch to the current user
  Future<XpEntity?> batchAwardXp(
    List<XpRewardType> rewardTypes, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('Cannot batch award XP: User not authenticated');
        return null;
      }

      final totalXp = rewardTypes.fold<int>(
        0,
        (sum, type) => sum + type.xpAmount,
      );
      debugPrint(
        'Batch awarding $totalXp XP for ${rewardTypes.length} actions',
      );

      final updatedXp = await _repository.batchAwardXp(
        currentUser.uid,
        rewardTypes,
        metadata: metadata,
      );

      debugPrint(
        'Batch XP awarded successfully. Total XP: ${updatedXp.totalXp}, Level: ${updatedXp.currentLevel}',
      );

      return updatedXp;
    } catch (e) {
      debugPrint('Error batch awarding XP: $e');
      return null;
    }
  }

  /// Get current user's XP data
  Future<XpEntity?> getCurrentUserXp() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('Cannot get XP: User not authenticated');
        return null;
      }

      return await _repository.getUserXp(currentUser.uid);
    } catch (e) {
      debugPrint('Error getting current user XP: $e');
      return null;
    }
  }

  /// Get XP data for any user by ID
  Future<XpEntity?> getUserXp(String userId) async {
    try {
      return await _repository.getUserXp(userId);
    } catch (e) {
      debugPrint('Error getting user XP for $userId: $e');
      return null;
    }
  }

  /// Get XP stream for current user (for real-time updates)
  Stream<XpEntity>? getCurrentUserXpStream() {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('Cannot get XP stream: User not authenticated');
        return null;
      }

      return _repository.getUserXpStream(currentUser.uid);
    } catch (e) {
      debugPrint('Error getting current user XP stream: $e');
      return null;
    }
  }

  /// Initialize XP for a new user (ensures totalXp field exists)
  Future<XpEntity?> initializeUserXp(String userId) async {
    try {
      debugPrint('Ensuring XP field exists for user $userId');

      final xpEntity = await _repository.initializeUserXp(userId);

      debugPrint('XP field ensured for user $userId');

      return xpEntity;
    } catch (e) {
      debugPrint('Error ensuring XP field for user $userId: $e');
      return null;
    }
  }

  /// Check if user has received a specific one-time reward
  Future<bool> hasReceivedReward(XpRewardType rewardType) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('Cannot check reward: User not authenticated');
        return false;
      }

      return await _repository.hasReceivedReward(currentUser.uid, rewardType);
    } catch (e) {
      debugPrint('Error checking reward: $e');
      return false;
    }
  }

  /// Get leaderboard
  Future<List<XpEntity>> getLeaderboard({int limit = 10}) async {
    try {
      return await _repository.getLeaderboard(limit: limit);
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      return [];
    }
  }

  /// Convenience methods for common actions

  /// Award XP for sending a message
  Future<XpEntity?> awardMessageSent({String? chatId}) async {
    return await awardXp(
      XpRewardType.sendMessage,
      metadata: chatId != null ? {'chatId': chatId} : null,
    );
  }

  /// Award XP for creating a fellowship
  Future<XpEntity?> awardFellowshipCreated(String fellowshipId) async {
    return await awardXp(
      XpRewardType.createFellowship,
      metadata: {'fellowshipId': fellowshipId},
    );
  }

  /// Award XP for joining a fellowship
  Future<XpEntity?> awardFellowshipJoined(String fellowshipId) async {
    return await awardXp(
      XpRewardType.joinFellowship,
      metadata: {'fellowshipId': fellowshipId},
    );
  }

  /// Award XP for creating a poll
  Future<XpEntity?> awardPollCreated(String pollId, String fellowshipId) async {
    return await awardXp(
      XpRewardType.createPoll,
      metadata: {'pollId': pollId, 'fellowshipId': fellowshipId},
    );
  }

  /// Award XP for voting on a poll
  Future<XpEntity?> awardVoteOnPoll(String pollId, String fellowshipId) async {
    return await awardXp(
      XpRewardType.voteOnPoll,
      metadata: {'pollId': pollId, 'fellowshipId': fellowshipId},
    );
  }

  /// Award XP for accepting a friend request
  Future<XpEntity?> awardFriendAdded(String friendId) async {
    return await awardXp(
      XpRewardType.acceptFriendRequest,
      metadata: {'friendId': friendId},
    );
  }

  /// Award XP for completing profile
  Future<XpEntity?> awardProfileCompleted() async {
    return await awardXp(XpRewardType.completeProfile);
  }

  /// Award XP for signing up (one-time reward)
  Future<XpEntity?> awardSignUp() async {
    return await awardXp(XpRewardType.signUp);
  }

  /// Award first-time action bonuses
  Future<XpEntity?> awardFirstMessage() async {
    return await awardXp(XpRewardType.firstMessage);
  }

  Future<XpEntity?> awardFirstFellowship() async {
    return await awardXp(XpRewardType.firstFellowship);
  }

  Future<XpEntity?> awardFirstPoll() async {
    return await awardXp(XpRewardType.firstPoll);
  }
}

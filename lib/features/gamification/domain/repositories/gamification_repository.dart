import 'package:critchat/features/gamification/domain/entities/xp_entity.dart';

/// Repository interface for gamification operations
abstract class GamificationRepository {
  /// Get user's current XP data
  Future<XpEntity> getUserXp(String userId);

  /// Award XP to a user for a specific action
  Future<XpEntity> awardXp(
    String userId,
    XpRewardType rewardType, {
    Map<String, dynamic>? metadata,
  });

  /// Get user's XP transaction history
  Future<List<XpTransactionEntity>> getUserXpHistory(
    String userId, {
    int limit = 50,
  });

  /// Get user's XP stream for real-time updates
  Stream<XpEntity> getUserXpStream(String userId);

  /// Initialize user's XP data (called when user signs up)
  Future<XpEntity> initializeUserXp(String userId);

  /// Get leaderboard (top users by XP)
  Future<List<XpEntity>> getLeaderboard({int limit = 10});

  /// Check if user has already received a specific one-time reward
  Future<bool> hasReceivedReward(String userId, XpRewardType rewardType);

  /// Batch award XP for multiple actions
  Future<XpEntity> batchAwardXp(
    String userId,
    List<XpRewardType> rewardTypes, {
    Map<String, dynamic>? metadata,
  });
}

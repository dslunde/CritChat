import 'dart:math' as math;
import 'package:equatable/equatable.dart';

/// Entity representing user XP and level information
class XpEntity extends Equatable {
  final String userId;
  final int totalXp;
  final int currentLevel;
  final int xpForCurrentLevel;
  final int xpForNextLevel;
  final DateTime lastUpdated;

  const XpEntity({
    required this.userId,
    required this.totalXp,
    required this.currentLevel,
    required this.xpForCurrentLevel,
    required this.xpForNextLevel,
    required this.lastUpdated,
  });

  /// Calculate the progress percentage towards the next level (0.0 to 1.0)
  double get progressToNextLevel {
    if (xpForNextLevel == xpForCurrentLevel) return 1.0;
    final currentProgress = totalXp - xpForCurrentLevel;
    final totalRequired = xpForNextLevel - xpForCurrentLevel;
    return (currentProgress / totalRequired).clamp(0.0, 1.0);
  }

  /// Get remaining XP needed for next level
  int get xpNeededForNextLevel {
    return (xpForNextLevel - totalXp).clamp(0, double.infinity).toInt();
  }

  /// Check if user just leveled up by comparing with previous state
  bool didLevelUp(XpEntity previous) {
    return currentLevel > previous.currentLevel;
  }

  /// Calculate level from total XP using exponential formula
  /// Formula: level = floor(sqrt(totalXp / 100))
  /// This means: Level 1 = 100 XP, Level 2 = 400 XP, Level 3 = 900 XP, etc.
  static int calculateLevelFromXp(int totalXp) {
    if (totalXp < 100) return 1;
    return (math.sqrt(totalXp / 100)).floor() + 1;
  }

  /// Calculate XP required for a specific level
  /// Formula: xp = (level - 1)² * 100
  static int calculateXpForLevel(int level) {
    if (level <= 1) return 0;
    return ((level - 1) * (level - 1) * 100);
  }

  /// Get the level title/name based on level number
  String get levelTitle {
    if (currentLevel < 5) return 'Novice';
    if (currentLevel < 10) return 'Apprentice';
    if (currentLevel < 20) return 'Adventurer';
    if (currentLevel < 35) return 'Veteran';
    if (currentLevel < 50) return 'Expert';
    if (currentLevel < 75) return 'Master';
    if (currentLevel < 100) return 'Grandmaster';
    return 'Legend';
  }

  /// Create an updated XP entity with new XP added
  XpEntity addXp(int xpToAdd) {
    final newTotalXp = totalXp + xpToAdd;
    final newLevel = calculateLevelFromXp(newTotalXp);
    final newXpForCurrentLevel = calculateXpForLevel(newLevel);
    final newXpForNextLevel = calculateXpForLevel(newLevel + 1);

    return XpEntity(
      userId: userId,
      totalXp: newTotalXp,
      currentLevel: newLevel,
      xpForCurrentLevel: newXpForCurrentLevel,
      xpForNextLevel: newXpForNextLevel,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    userId,
    totalXp,
    currentLevel,
    xpForCurrentLevel,
    xpForNextLevel,
    lastUpdated,
  ];
}

/// Enum defining different types of XP rewards
enum XpRewardType {
  // Authentication & Profile
  signUp(10, 'Account Created'),
  completeProfile(25, 'Profile Completed'),

  // Social Actions
  sendMessage(2, 'Message Sent'),
  receiveFriendRequest(5, 'Friend Request Received'),
  acceptFriendRequest(10, 'Friend Added'),

  // Fellowship Actions
  createFellowship(50, 'Fellowship Created'),
  joinFellowship(25, 'Fellowship Joined'),
  inviteFriend(15, 'Friend Invited'),

  // Poll Actions
  createPoll(20, 'Poll Created'),
  voteOnPoll(5, 'Vote Cast'),
  addCustomOption(10, 'Option Added'),

  // Content Creation
  createPost(15, 'Post Created'),
  createStory(10, 'Story Shared'),
  createRecap(30, 'Session Recap'),

  // Engagement
  likePost(1, 'Post Liked'),
  commentOnPost(3, 'Comment Added'),
  shareContent(5, 'Content Shared'),

  // Special Achievements
  firstMessage(25, 'First Message'),
  firstFellowship(50, 'First Fellowship'),
  firstPoll(25, 'First Poll'),
  weeklyActive(20, 'Weekly Active'),
  monthlyActive(50, 'Monthly Active');

  const XpRewardType(this.xpAmount, this.description);

  final int xpAmount;
  final String description;
}

/// Entity representing an XP transaction/reward
class XpTransactionEntity extends Equatable {
  final String id;
  final String userId;
  final XpRewardType rewardType;
  final int xpAwarded;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const XpTransactionEntity({
    required this.id,
    required this.userId,
    required this.rewardType,
    required this.xpAwarded,
    required this.description,
    required this.timestamp,
    this.metadata,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    rewardType,
    xpAwarded,
    description,
    timestamp,
    metadata,
  ];
}

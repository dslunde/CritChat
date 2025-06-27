import 'package:critchat/features/gamification/domain/entities/xp_entity.dart';
import 'package:critchat/features/gamification/domain/repositories/gamification_repository.dart';

/// Use case for awarding XP to a user
class AwardXpUseCase {
  final GamificationRepository repository;

  AwardXpUseCase({required this.repository});

  Future<XpEntity> call(
    String userId,
    XpRewardType rewardType, {
    Map<String, dynamic>? metadata,
  }) async {
    // Check if this is a one-time reward that the user has already received
    final oneTimeRewards = {
      XpRewardType.signUp,
      XpRewardType.completeProfile,
      XpRewardType.firstMessage,
      XpRewardType.firstFellowship,
      XpRewardType.firstPoll,
    };

    if (oneTimeRewards.contains(rewardType)) {
      final hasReceived = await repository.hasReceivedReward(
        userId,
        rewardType,
      );
      if (hasReceived) {
        // User has already received this one-time reward, return current XP without awarding
        return await repository.getUserXp(userId);
      }
    }

    return await repository.awardXp(userId, rewardType, metadata: metadata);
  }
}

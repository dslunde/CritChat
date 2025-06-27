import 'package:equatable/equatable.dart';
import 'package:critchat/features/gamification/domain/entities/xp_entity.dart';

/// Base class for gamification events
abstract class GamificationEvent extends Equatable {
  const GamificationEvent();

  @override
  List<Object?> get props => [];
}

/// Event to get user's current XP
class GetUserXp extends GamificationEvent {
  final String userId;

  const GetUserXp({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Event to award XP to a user
class AwardXp extends GamificationEvent {
  final String userId;
  final XpRewardType rewardType;
  final Map<String, dynamic>? metadata;

  const AwardXp({
    required this.userId,
    required this.rewardType,
    this.metadata,
  });

  @override
  List<Object?> get props => [userId, rewardType, metadata];
}

/// Event to get user's XP history
class GetXpHistory extends GamificationEvent {
  final String userId;
  final int limit;

  const GetXpHistory({required this.userId, this.limit = 50});

  @override
  List<Object?> get props => [userId, limit];
}

/// Event to start listening to user's XP stream
class StartXpStream extends GamificationEvent {
  final String userId;

  const StartXpStream({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Event to stop listening to user's XP stream
class StopXpStream extends GamificationEvent {}

/// Event when XP is updated via stream
class XpUpdated extends GamificationEvent {
  final XpEntity xpEntity;

  const XpUpdated({required this.xpEntity});

  @override
  List<Object?> get props => [xpEntity];
}

/// Event to get leaderboard
class GetLeaderboard extends GamificationEvent {
  final int limit;

  const GetLeaderboard({this.limit = 10});

  @override
  List<Object?> get props => [limit];
}

/// Event to initialize user XP (typically called on signup)
class InitializeUserXp extends GamificationEvent {
  final String userId;

  const InitializeUserXp({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Event to batch award XP for multiple actions
class BatchAwardXp extends GamificationEvent {
  final String userId;
  final List<XpRewardType> rewardTypes;
  final Map<String, dynamic>? metadata;

  const BatchAwardXp({
    required this.userId,
    required this.rewardTypes,
    this.metadata,
  });

  @override
  List<Object?> get props => [userId, rewardTypes, metadata];
}

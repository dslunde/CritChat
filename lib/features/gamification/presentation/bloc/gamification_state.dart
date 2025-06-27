import 'package:equatable/equatable.dart';
import 'package:critchat/features/gamification/domain/entities/xp_entity.dart';

/// Base class for gamification states
abstract class GamificationState extends Equatable {
  const GamificationState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class GamificationInitial extends GamificationState {}

/// Loading state
class GamificationLoading extends GamificationState {}

/// State when user XP is loaded
class UserXpLoaded extends GamificationState {
  final XpEntity xpEntity;

  const UserXpLoaded({required this.xpEntity});

  @override
  List<Object?> get props => [xpEntity];
}

/// State when XP is awarded successfully
class XpAwarded extends GamificationState {
  final XpEntity xpEntity;
  final XpRewardType rewardType;
  final bool leveledUp;

  const XpAwarded({
    required this.xpEntity,
    required this.rewardType,
    required this.leveledUp,
  });

  @override
  List<Object?> get props => [xpEntity, rewardType, leveledUp];
}

/// State when XP history is loaded
class XpHistoryLoaded extends GamificationState {
  final List<XpTransactionEntity> transactions;

  const XpHistoryLoaded({required this.transactions});

  @override
  List<Object?> get props => [transactions];
}

/// State when leaderboard is loaded
class LeaderboardLoaded extends GamificationState {
  final List<XpEntity> leaderboard;

  const LeaderboardLoaded({required this.leaderboard});

  @override
  List<Object?> get props => [leaderboard];
}

/// State when user XP is initialized
class UserXpInitialized extends GamificationState {
  final XpEntity xpEntity;

  const UserXpInitialized({required this.xpEntity});

  @override
  List<Object?> get props => [xpEntity];
}

/// State when XP is being streamed (real-time updates)
class XpStreaming extends GamificationState {
  final XpEntity xpEntity;

  const XpStreaming({required this.xpEntity});

  @override
  List<Object?> get props => [xpEntity];
}

/// State when batch XP is awarded
class BatchXpAwarded extends GamificationState {
  final XpEntity xpEntity;
  final List<XpRewardType> rewardTypes;
  final bool leveledUp;

  const BatchXpAwarded({
    required this.xpEntity,
    required this.rewardTypes,
    required this.leveledUp,
  });

  @override
  List<Object?> get props => [xpEntity, rewardTypes, leveledUp];
}

/// Error state
class GamificationError extends GamificationState {
  final String message;

  const GamificationError({required this.message});

  @override
  List<Object?> get props => [message];
}

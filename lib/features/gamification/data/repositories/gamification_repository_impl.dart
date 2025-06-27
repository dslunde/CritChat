import 'package:critchat/features/gamification/data/datasources/gamification_firestore_datasource.dart';
import 'package:critchat/features/gamification/domain/entities/xp_entity.dart';
import 'package:critchat/features/gamification/domain/repositories/gamification_repository.dart';

/// Implementation of GamificationRepository
class GamificationRepositoryImpl implements GamificationRepository {
  final GamificationFirestoreDataSource dataSource;

  GamificationRepositoryImpl({required this.dataSource});

  @override
  Future<XpEntity> getUserXp(String userId) async {
    return await dataSource.getUserXp(userId);
  }

  @override
  Future<XpEntity> awardXp(
    String userId,
    XpRewardType rewardType, {
    Map<String, dynamic>? metadata,
  }) async {
    return await dataSource.awardXp(userId, rewardType, metadata: metadata);
  }

  @override
  Future<List<XpTransactionEntity>> getUserXpHistory(
    String userId, {
    int limit = 50,
  }) async {
    final models = await dataSource.getUserXpHistory(userId, limit: limit);
    return models.cast<XpTransactionEntity>();
  }

  @override
  Stream<XpEntity> getUserXpStream(String userId) {
    return dataSource.getUserXpStream(userId).cast<XpEntity>();
  }

  @override
  Future<XpEntity> initializeUserXp(String userId) async {
    return await dataSource.initializeUserXp(userId);
  }

  @override
  Future<List<XpEntity>> getLeaderboard({int limit = 10}) async {
    final models = await dataSource.getLeaderboard(limit: limit);
    return models.cast<XpEntity>();
  }

  @override
  Future<bool> hasReceivedReward(String userId, XpRewardType rewardType) async {
    return await dataSource.hasReceivedReward(userId, rewardType);
  }

  @override
  Future<XpEntity> batchAwardXp(
    String userId,
    List<XpRewardType> rewardTypes, {
    Map<String, dynamic>? metadata,
  }) async {
    return await dataSource.batchAwardXp(
      userId,
      rewardTypes,
      metadata: metadata,
    );
  }
}

import 'package:critchat/features/gamification/domain/entities/xp_entity.dart';
import 'package:critchat/features/gamification/domain/repositories/gamification_repository.dart';

/// Use case for initializing user's XP data when they sign up
class InitializeUserXpUseCase {
  final GamificationRepository repository;

  InitializeUserXpUseCase({required this.repository});

  Future<XpEntity> call(String userId) async {
    return await repository.initializeUserXp(userId);
  }
}

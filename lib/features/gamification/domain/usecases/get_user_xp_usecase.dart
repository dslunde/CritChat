import 'package:critchat/features/gamification/domain/entities/xp_entity.dart';
import 'package:critchat/features/gamification/domain/repositories/gamification_repository.dart';

/// Use case for getting user's current XP data
class GetUserXpUseCase {
  final GamificationRepository repository;

  GetUserXpUseCase({required this.repository});

  Future<XpEntity> call(String userId) async {
    return await repository.getUserXp(userId);
  }
}

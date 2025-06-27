import 'package:critchat/features/gamification/domain/entities/xp_entity.dart';
import 'package:critchat/features/gamification/domain/repositories/gamification_repository.dart';

/// Use case for getting user's XP stream for real-time updates
class GetUserXpStreamUseCase {
  final GamificationRepository repository;

  GetUserXpStreamUseCase({required this.repository});

  Stream<XpEntity> call(String userId) {
    return repository.getUserXpStream(userId);
  }
}

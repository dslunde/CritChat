import 'package:critchat/features/lfg/domain/entities/lfg_post_entity.dart';
import 'package:critchat/features/lfg/domain/repositories/lfg_repository.dart';

class CreateLfgPostUseCase {
  final LfgRepository repository;

  CreateLfgPostUseCase({required this.repository});

  Future<LfgPostEntity> call({
    required String userId,
    required String userName,
    required int userLevel,
    required String gameSystem,
    required List<String> playStyles,
    required String sessionFormat,
    required String schedulePreference,
    required String campaignLength,
    required String callToAdventureText,
  }) async {
    // Check if user has reached the limit of active posts (5)
    final activePostCount = await repository.getUserActivePostCount(userId);
    if (activePostCount >= 5) {
      throw Exception('You have reached the maximum limit of 5 active LFG posts.');
    }

    final now = DateTime.now();
    final post = LfgPostEntity(
      id: '', // Will be set by the datasource
      userId: userId,
      userName: userName,
      userLevel: userLevel,
      gameSystem: gameSystem,
      playStyles: playStyles,
      sessionFormat: sessionFormat,
      schedulePreference: schedulePreference,
      campaignLength: campaignLength,
      callToAdventureText: callToAdventureText,
      createdAt: now,
      isClosed: false,
      interestedUserIds: [],
    );

    return await repository.createLfgPost(post);
  }
} 
import 'package:critchat/features/lfg/domain/entities/lfg_post_entity.dart';
import 'package:critchat/features/lfg/domain/repositories/lfg_repository.dart';
import 'package:critchat/features/fellowships/domain/entities/fellowship_entity.dart';
import 'package:critchat/features/fellowships/domain/repositories/fellowship_repository.dart';

class CreateFellowshipFromPostUseCase {
  final LfgRepository lfgRepository;
  final FellowshipRepository fellowshipRepository;

  CreateFellowshipFromPostUseCase({
    required this.lfgRepository,
    required this.fellowshipRepository,
  });

  Future<FellowshipEntity> call({
    required String postId,
    required String fellowshipName,
    required String fellowshipDescription,
    required bool isPublic,
    String? joinCode,
  }) async {
    // Get the LFG post to access the interested users
    final userPosts = await lfgRepository.getUserLfgPosts('');
    final post = userPosts.firstWhere((p) => p.id == postId);
    
    // Create the fellowship
    final fellowship = await fellowshipRepository.createFellowship(
      name: fellowshipName,
      description: fellowshipDescription,
      gameSystem: post.gameSystem,
      isPublic: isPublic,
      creatorId: post.userId,
      joinCode: joinCode,
    );

    // Invite all interested users to the fellowship
    for (final userId in post.interestedUserIds) {
      await fellowshipRepository.inviteFriendToFellowship(fellowship.id, userId);
    }

    // Close the LFG post
    await lfgRepository.closeLfgPost(postId);

    return fellowship;
  }
} 
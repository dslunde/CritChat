import 'package:critchat/features/lfg/domain/entities/lfg_post_entity.dart';
import 'package:critchat/features/lfg/domain/repositories/lfg_repository.dart';

class GetActiveLfgPostsUseCase {
  final LfgRepository repository;

  GetActiveLfgPostsUseCase({required this.repository});

  Future<List<LfgPostEntity>> call(String currentUserId) {
    return repository.getActiveLfgPosts(currentUserId);
  }
} 
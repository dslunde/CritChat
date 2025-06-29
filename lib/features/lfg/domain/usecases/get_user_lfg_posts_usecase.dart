import 'package:critchat/features/lfg/domain/entities/lfg_post_entity.dart';
import 'package:critchat/features/lfg/domain/repositories/lfg_repository.dart';

class GetUserLfgPostsUseCase {
  final LfgRepository repository;

  GetUserLfgPostsUseCase({required this.repository});

  Future<List<LfgPostEntity>> call(String userId) {
    return repository.getUserLfgPosts(userId);
  }
} 
import 'package:critchat/features/lfg/domain/entities/lfg_post_entity.dart';
import 'package:critchat/features/lfg/domain/repositories/lfg_repository.dart';

class RefreshLfgPostUseCase {
  final LfgRepository repository;

  RefreshLfgPostUseCase({required this.repository});

  Future<LfgPostEntity> call(String postId) {
    return repository.refreshLfgPost(postId);
  }
} 
import 'package:critchat/features/lfg/domain/repositories/lfg_repository.dart';

class CloseLfgPostUseCase {
  final LfgRepository repository;

  CloseLfgPostUseCase({required this.repository});

  Future<bool> call(String postId) {
    return repository.closeLfgPost(postId);
  }
} 
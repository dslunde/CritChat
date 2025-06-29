import 'package:critchat/features/lfg/domain/repositories/lfg_repository.dart';

class ExpressInterestUseCase {
  final LfgRepository repository;

  ExpressInterestUseCase({required this.repository});

  Future<bool> call({
    required String postId,
    required String userId,
  }) {
    return repository.expressInterest(postId, userId);
  }
} 
import 'package:critchat/features/fellowships/domain/repositories/fellowship_repository.dart';

class JoinFellowshipByCodeUseCase {
  final FellowshipRepository repository;

  JoinFellowshipByCodeUseCase({required this.repository});

  Future<bool> call({
    required String name,
    required String joinCode,
    required String userId,
  }) {
    return repository.joinFellowshipByCode(name, joinCode, userId);
  }
}

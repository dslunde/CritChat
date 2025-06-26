import 'package:critchat/features/fellowships/domain/entities/fellowship_entity.dart';
import 'package:critchat/features/fellowships/domain/repositories/fellowship_repository.dart';

class CreateFellowshipUseCase {
  final FellowshipRepository repository;

  CreateFellowshipUseCase({required this.repository});

  Future<FellowshipEntity> call({
    required String name,
    required String description,
    required String gameSystem,
    required bool isPublic,
    required String creatorId,
    String? joinCode,
  }) {
    return repository.createFellowship(
      name: name,
      description: description,
      gameSystem: gameSystem,
      isPublic: isPublic,
      creatorId: creatorId,
      joinCode: joinCode,
    );
  }
}

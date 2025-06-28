import 'package:critchat/features/characters/domain/entities/character_entity.dart';
import 'package:critchat/features/characters/domain/repositories/character_repository.dart';

class GetUserCharacterUseCase {
  final CharacterRepository repository;

  GetUserCharacterUseCase({required this.repository});

  Future<CharacterEntity?> call(String userId) async {
    if (userId.trim().isEmpty) {
      throw Exception('User ID cannot be empty');
    }

    return await repository.getUserCharacter(userId);
  }
} 
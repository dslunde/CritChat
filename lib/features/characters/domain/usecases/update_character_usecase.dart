import 'package:critchat/features/characters/domain/entities/character_entity.dart';
import 'package:critchat/features/characters/domain/repositories/character_repository.dart';

class UpdateCharacterUseCase {
  final CharacterRepository repository;

  UpdateCharacterUseCase({required this.repository});

  Future<CharacterEntity> call({
    required String characterId,
    required String userId,
    String? name,
    String? description,
    String? personality,
    String? backstory,
    String? speechPatterns,
    List<String>? quotes,
  }) async {
    // Get existing character
    final existingCharacter = await repository.getCharacterById(characterId);
    if (existingCharacter == null) {
      throw Exception('Character not found');
    }

    // Verify ownership
    if (existingCharacter.userId != userId) {
      throw Exception('You can only update your own character');
    }

    // Validation for updated fields
    if (name != null && name.trim().isEmpty) {
      throw Exception('Character name cannot be empty');
    }

    if (name != null && name.trim().length > 30) {
      throw Exception('Character name cannot exceed 30 characters');
    }

    if (description != null && description.trim().isEmpty) {
      throw Exception('Character description cannot be empty');
    }

    if (description != null && description.trim().length > 500) {
      throw Exception('Character description cannot exceed 500 characters');
    }

    if (personality != null && personality.trim().isEmpty) {
      throw Exception('Character personality cannot be empty');
    }

    if (personality != null && personality.trim().length > 1000) {
      throw Exception('Character personality cannot exceed 1000 characters');
    }

    if (backstory != null && backstory.trim().length > 2000) {
      throw Exception('Character backstory cannot exceed 2000 characters');
    }

    if (speechPatterns != null && speechPatterns.trim().length > 1000) {
      throw Exception('Speech patterns cannot exceed 1000 characters');
    }

    // Validate quotes
    if (quotes != null) {
      for (final quote in quotes) {
        if (quote.trim().length > 200) {
          throw Exception('Character quotes cannot exceed 200 characters each');
        }
      }

      if (quotes.length > 10) {
        throw Exception('Character cannot have more than 10 quotes');
      }
    }

    // Check for name uniqueness if name is being changed
    if (name != null && name.trim() != existingCharacter.name) {
      final existingWithName = await repository.getCharacterByNameAndUser(
        name.trim(),
        userId,
      );
      if (existingWithName != null && existingWithName.id != characterId) {
        throw Exception('You already have a character with this name');
      }
    }

    final updatedCharacter = existingCharacter.copyWith(
      name: name?.trim(),
      description: description?.trim(),
      personality: personality?.trim(),
      backstory: backstory?.trim(),
      speechPatterns: speechPatterns?.trim(),
      quotes: quotes?.map((q) => q.trim()).where((q) => q.isNotEmpty).toList(),
      updatedAt: DateTime.now(),
      // Reset indexing status if character content changed
      isIndexed: (name != null || description != null || personality != null || 
                  backstory != null || speechPatterns != null || quotes != null)
                  ? false : existingCharacter.isIndexed,
    );

    return await repository.updateCharacter(updatedCharacter);
  }
} 
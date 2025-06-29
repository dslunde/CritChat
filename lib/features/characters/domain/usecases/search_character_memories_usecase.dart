import 'package:critchat/features/characters/domain/entities/character_memory_entity.dart';
import 'package:critchat/features/characters/domain/repositories/character_memory_repository.dart';

class SearchCharacterMemoriesUseCase {
  final CharacterMemoryRepository repository;

  SearchCharacterMemoriesUseCase({required this.repository});

  Future<List<CharacterMemoryEntity>> call({
    required String characterId,
    required String query,
    int limit = 10,
    double minSimilarity = 0.1,
  }) async {
    // Validation
    if (characterId.trim().isEmpty) {
      throw Exception('Character ID cannot be empty');
    }

    if (query.trim().isEmpty) {
      throw Exception('Search query cannot be empty');
    }

    if (limit < 1 || limit > 20) {
      throw Exception('Limit must be between 1 and 20');
    }

    if (minSimilarity < 0.0 || minSimilarity > 1.0) {
      throw Exception('Minimum similarity must be between 0.0 and 1.0');
    }

    try {
      return await repository.searchMemoriesByText(
        characterId: characterId,
        query: query.trim(),
        limit: limit,
        minSimilarity: minSimilarity,
      );
    } catch (e) {
      // If vector search fails, return empty list gracefully
      // This allows the character system to continue working even if the vector database is down
      return [];
    }
  }

  /// Get memories by content type for more targeted retrieval
  Future<List<CharacterMemoryEntity>> getMemoriesByType({
    required String characterId,
    required String contentType,
    int limit = 10,
  }) async {
    if (characterId.trim().isEmpty) {
      throw Exception('Character ID cannot be empty');
    }

    if (contentType.trim().isEmpty) {
      throw Exception('Content type cannot be empty');
    }

    if (limit < 1 || limit > 50) {
      throw Exception('Limit must be between 1 and 50');
    }

    try {
      return await repository.getMemoriesByType(
        characterId: characterId,
        contentType: contentType.trim(),
        limit: limit,
      );
    } catch (e) {
      return [];
    }
  }

  /// Get all memories for a character (for management/viewing purposes)
  Future<List<CharacterMemoryEntity>> getAllCharacterMemories({
    required String characterId,
  }) async {
    if (characterId.trim().isEmpty) {
      throw Exception('Character ID cannot be empty');
    }

    try {
      return await repository.getCharacterMemories(characterId);
    } catch (e) {
      return [];
    }
  }
} 
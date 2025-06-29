import 'package:critchat/features/characters/domain/entities/character_memory_entity.dart';

abstract class CharacterMemoryRepository {
  /// Store a new character memory in the vector database
  Future<CharacterMemoryEntity> storeMemory(CharacterMemoryEntity memory);
  
  /// Update an existing character memory
  Future<CharacterMemoryEntity> updateMemory(CharacterMemoryEntity memory);
  
  /// Delete a character memory
  Future<void> deleteMemory(String memoryId);
  
  /// Get all memories for a specific character
  Future<List<CharacterMemoryEntity>> getCharacterMemories(String characterId);
  
  /// Search for memories similar to a query embedding
  Future<List<CharacterMemoryEntity>> searchSimilarMemories({
    required String characterId,
    required List<double> queryEmbedding,
    int limit = 10,
    double minSimilarity = 0.0,
  });
  
  /// Search for memories similar to a text query (will be embedded)
  Future<List<CharacterMemoryEntity>> searchMemoriesByText({
    required String characterId,
    required String query,
    int limit = 10,
    double minSimilarity = 0.0,
  });
  
  /// Get memories by content type
  Future<List<CharacterMemoryEntity>> getMemoriesByType({
    required String characterId,
    required String contentType,
    int limit = 50,
  });
  
  /// Get memory by ID
  Future<CharacterMemoryEntity?> getMemoryById(String memoryId);
  
  /// Delete all memories for a character (when character is deleted)
  Future<void> deleteAllCharacterMemories(String characterId);
  
  /// Check if vector database is available and healthy
  Future<bool> isVectorDatabaseHealthy();
} 
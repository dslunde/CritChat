import 'package:critchat/features/characters/domain/entities/character_memory_entity.dart';
import 'package:critchat/features/characters/domain/repositories/character_memory_repository.dart';
import 'package:critchat/features/characters/data/datasources/character_memory_weaviate_datasource.dart';
import 'package:critchat/features/characters/data/models/character_memory_model.dart';

class CharacterMemoryRepositoryImpl implements CharacterMemoryRepository {
  final CharacterMemoryWeaviateDataSource dataSource;

  CharacterMemoryRepositoryImpl({required this.dataSource});

  @override
  Future<CharacterMemoryEntity> storeMemory(CharacterMemoryEntity memory) async {
    try {
      final memoryModel = CharacterMemoryModel.fromEntity(memory);
      return await dataSource.storeMemory(memoryModel);
    } catch (e) {
      throw Exception('Failed to store character memory: ${e.toString()}');
    }
  }

  @override
  Future<CharacterMemoryEntity> updateMemory(CharacterMemoryEntity memory) async {
    try {
      final memoryModel = CharacterMemoryModel.fromEntity(memory);
      return await dataSource.updateMemory(memoryModel);
    } catch (e) {
      throw Exception('Failed to update character memory: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteMemory(String memoryId) async {
    try {
      await dataSource.deleteMemory(memoryId);
    } catch (e) {
      throw Exception('Failed to delete character memory: ${e.toString()}');
    }
  }

  @override
  Future<List<CharacterMemoryEntity>> getCharacterMemories(String characterId) async {
    try {
      final memories = await dataSource.getCharacterMemories(characterId);
      return memories.cast<CharacterMemoryEntity>();
    } catch (e) {
      throw Exception('Failed to get character memories: ${e.toString()}');
    }
  }

  @override
  Future<List<CharacterMemoryEntity>> searchSimilarMemories({
    required String characterId,
    required List<double> queryEmbedding,
    int limit = 10,
    double minSimilarity = 0.0,
  }) async {
    try {
      final memories = await dataSource.searchSimilarMemories(
        characterId: characterId,
        queryEmbedding: queryEmbedding,
        limit: limit,
        minSimilarity: minSimilarity,
      );
      return memories.cast<CharacterMemoryEntity>();
    } catch (e) {
      throw Exception('Failed to search similar memories: ${e.toString()}');
    }
  }

  @override
  Future<List<CharacterMemoryEntity>> searchMemoriesByText({
    required String characterId,
    required String query,
    int limit = 10,
    double minSimilarity = 0.0,
  }) async {
    try {
      final memories = await dataSource.searchMemoriesByText(
        characterId: characterId,
        query: query,
        limit: limit,
        minSimilarity: minSimilarity,
      );
      return memories.cast<CharacterMemoryEntity>();
    } catch (e) {
      throw Exception('Failed to search memories by text: ${e.toString()}');
    }
  }

  @override
  Future<List<CharacterMemoryEntity>> getMemoriesByType({
    required String characterId,
    required String contentType,
    int limit = 50,
  }) async {
    try {
      final memories = await dataSource.getMemoriesByType(
        characterId: characterId,
        contentType: contentType,
        limit: limit,
      );
      return memories.cast<CharacterMemoryEntity>();
    } catch (e) {
      throw Exception('Failed to get memories by type: ${e.toString()}');
    }
  }

  @override
  Future<CharacterMemoryEntity?> getMemoryById(String memoryId) async {
    try {
      return await dataSource.getMemoryById(memoryId);
    } catch (e) {
      throw Exception('Failed to get memory by ID: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAllCharacterMemories(String characterId) async {
    try {
      await dataSource.deleteAllCharacterMemories(characterId);
    } catch (e) {
      throw Exception('Failed to delete all character memories: ${e.toString()}');
    }
  }

  @override
  Future<bool> isVectorDatabaseHealthy() async {
    try {
      return await dataSource.isHealthy();
    } catch (e) {
      return false;
    }
  }
} 
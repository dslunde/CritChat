import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:critchat/features/characters/data/models/character_memory_model.dart';
import 'package:critchat/core/vector_db/weaviate_service.dart';
import 'package:critchat/core/embeddings/embedding_service.dart';

abstract class CharacterMemoryWeaviateDataSource {
  Future<CharacterMemoryModel> storeMemory(CharacterMemoryModel memory);
  Future<CharacterMemoryModel> updateMemory(CharacterMemoryModel memory);
  Future<void> deleteMemory(String memoryId);
  Future<List<CharacterMemoryModel>> getCharacterMemories(String characterId);
  Future<List<CharacterMemoryModel>> searchSimilarMemories({
    required String characterId,
    required List<double> queryEmbedding,
    int limit = 10,
    double minSimilarity = 0.0,
  });
  Future<List<CharacterMemoryModel>> searchMemoriesByText({
    required String characterId,
    required String query,
    int limit = 10,
    double minSimilarity = 0.0,
  });
  Future<List<CharacterMemoryModel>> getMemoriesByType({
    required String characterId,
    required String contentType,
    int limit = 50,
  });
  Future<CharacterMemoryModel?> getMemoryById(String memoryId);
  Future<void> deleteAllCharacterMemories(String characterId);
  Future<bool> isHealthy();
}

class CharacterMemoryWeaviateDataSourceImpl implements CharacterMemoryWeaviateDataSource {
  final WeaviateService weaviateService;
  final EmbeddingService embeddingService;
  final Uuid uuid;

  CharacterMemoryWeaviateDataSourceImpl({
    required this.weaviateService,
    required this.embeddingService,
    Uuid? uuid,
  }) : uuid = uuid ?? const Uuid();

  @override
  Future<CharacterMemoryModel> storeMemory(CharacterMemoryModel memory) async {
    try {
      // Generate unique ID if not provided
      final memoryId = memory.id.isNotEmpty ? memory.id : uuid.v4();
      
      final memoryWithId = memory.copyWith(id: memoryId);
      
      // Store in Weaviate
      final storedId = await weaviateService.storeMemory(memoryWithId);
      
      debugPrint('✅ Stored character memory with ID: $storedId');
      
      return memoryWithId.copyWith(id: storedId);
    } catch (e) {
      debugPrint('❌ Failed to store character memory: $e');
      throw Exception('Failed to store character memory: $e');
    }
  }

  @override
  Future<CharacterMemoryModel> updateMemory(CharacterMemoryModel memory) async {
    try {
      // For Weaviate, update is effectively delete + create
      if (memory.id.isNotEmpty) {
        await deleteMemory(memory.id);
      }
      
      // Store updated memory
      final updatedMemory = memory.copyWith(updatedAt: DateTime.now());
      return await storeMemory(updatedMemory);
    } catch (e) {
      debugPrint('❌ Failed to update character memory: $e');
      throw Exception('Failed to update character memory: $e');
    }
  }

  @override
  Future<void> deleteMemory(String memoryId) async {
    try {
      await weaviateService.deleteMemory(memoryId);
      debugPrint('✅ Deleted character memory: $memoryId');
    } catch (e) {
      debugPrint('❌ Failed to delete character memory: $e');
      throw Exception('Failed to delete character memory: $e');
    }
  }

  @override
  Future<List<CharacterMemoryModel>> getCharacterMemories(String characterId) async {
    try {
      final memoriesJson = await weaviateService.getCharacterMemories(characterId);
      
      final memories = memoriesJson
          .map((json) => CharacterMemoryModel.fromWeaviateJson(json))
          .toList();
      
      debugPrint('✅ Retrieved ${memories.length} memories for character: $characterId');
      return memories;
    } catch (e) {
      debugPrint('❌ Failed to get character memories: $e');
      throw Exception('Failed to get character memories: $e');
    }
  }

  @override
  Future<List<CharacterMemoryModel>> searchSimilarMemories({
    required String characterId,
    required List<double> queryEmbedding,
    int limit = 10,
    double minSimilarity = 0.0,
  }) async {
    try {
      final memoriesJson = await weaviateService.searchSimilarMemories(
        characterId: characterId,
        queryVector: queryEmbedding,
        limit: limit,
        minSimilarity: minSimilarity,
      );

      final memories = memoriesJson.map((json) {
        final memory = CharacterMemoryModel.fromWeaviateJson(json);
        
        // Add similarity score from Weaviate response
        final certainty = json['_additional']?['certainty'] as double?;
        if (certainty != null) {
          // Convert Weaviate certainty (0.5-1.0) to similarity (0.0-1.0)
          final similarity = (certainty - 0.5) * 2;
          return memory.withSimilarity(similarity);
        }
        
        return memory;
      }).toList();

      // Sort by similarity score if available
      memories.sort((a, b) {
        final simA = a.similarity ?? 0.0;
        final simB = b.similarity ?? 0.0;
        return simB.compareTo(simA); // Descending order
      });

      debugPrint('✅ Found ${memories.length} similar memories for character: $characterId');
      return memories;
    } catch (e) {
      debugPrint('❌ Failed to search similar memories: $e');
      throw Exception('Failed to search similar memories: $e');
    }
  }

  @override
  Future<List<CharacterMemoryModel>> searchMemoriesByText({
    required String characterId,
    required String query,
    int limit = 10,
    double minSimilarity = 0.0,
  }) async {
    try {
      // Generate embedding for the query text
      final queryEmbedding = await embeddingService.generateEmbedding(query);
      
      // Search using the embedding
      return await searchSimilarMemories(
        characterId: characterId,
        queryEmbedding: queryEmbedding,
        limit: limit,
        minSimilarity: minSimilarity,
      );
    } catch (e) {
      debugPrint('❌ Failed to search memories by text: $e');
      throw Exception('Failed to search memories by text: $e');
    }
  }

  @override
  Future<List<CharacterMemoryModel>> getMemoriesByType({
    required String characterId,
    required String contentType,
    int limit = 50,
  }) async {
    try {
      // For now, get all memories and filter by type
      // TODO: Optimize with Weaviate where clause on contentType
      final allMemories = await getCharacterMemories(characterId);
      
      final filteredMemories = allMemories
          .where((memory) => memory.contentType == contentType)
          .take(limit)
          .toList();

      debugPrint('✅ Found ${filteredMemories.length} memories of type "$contentType" for character: $characterId');
      return filteredMemories;
    } catch (e) {
      debugPrint('❌ Failed to get memories by type: $e');
      throw Exception('Failed to get memories by type: $e');
    }
  }

  @override
  Future<CharacterMemoryModel?> getMemoryById(String memoryId) async {
    try {
      // For Weaviate, we would need to implement object retrieval by ID
      // For now, this is a placeholder implementation
      debugPrint('⚠️ getMemoryById not fully implemented for Weaviate');
      return null;
    } catch (e) {
      debugPrint('❌ Failed to get memory by ID: $e');
      throw Exception('Failed to get memory by ID: $e');
    }
  }

  @override
  Future<void> deleteAllCharacterMemories(String characterId) async {
    try {
      await weaviateService.deleteAllCharacterMemories(characterId);
      debugPrint('✅ Deleted all memories for character: $characterId');
    } catch (e) {
      debugPrint('❌ Failed to delete all character memories: $e');
      throw Exception('Failed to delete all character memories: $e');
    }
  }

  @override
  Future<bool> isHealthy() async {
    try {
      return await weaviateService.isHealthy();
    } catch (e) {
      debugPrint('🔍 Weaviate health check failed: $e');
      return false;
    }
  }
} 
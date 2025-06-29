import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:critchat/features/characters/data/models/character_memory_model.dart';
import 'package:critchat/features/characters/data/datasources/character_memory_weaviate_datasource.dart';

class CharacterMemoryMockDataSourceImpl implements CharacterMemoryWeaviateDataSource {
  final Map<String, CharacterMemoryModel> _memories = {};
  final Uuid uuid;

  CharacterMemoryMockDataSourceImpl({Uuid? uuid}) : uuid = uuid ?? const Uuid();

  @override
  Future<CharacterMemoryModel> storeMemory(CharacterMemoryModel memory) async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
    
    final memoryId = memory.id.isNotEmpty ? memory.id : uuid.v4();
    final memoryWithId = memory.copyWith(id: memoryId);
    
    _memories[memoryId] = memoryWithId;
    
    debugPrint('📝 Mock: Stored character memory with ID: $memoryId');
    return memoryWithId;
  }

  @override
  Future<CharacterMemoryModel> updateMemory(CharacterMemoryModel memory) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!_memories.containsKey(memory.id)) {
      throw Exception('Memory not found: ${memory.id}');
    }
    
    final updatedMemory = memory.copyWith(updatedAt: DateTime.now());
    _memories[memory.id] = updatedMemory;
    
    debugPrint('🔄 Mock: Updated character memory: ${memory.id}');
    return updatedMemory;
  }

  @override
  Future<void> deleteMemory(String memoryId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    
    _memories.remove(memoryId);
    debugPrint('🗑️ Mock: Deleted character memory: $memoryId');
  }

  @override
  Future<List<CharacterMemoryModel>> getCharacterMemories(String characterId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    final memories = _memories.values
        .where((memory) => memory.characterId == characterId)
        .toList();
    
    // Sort by creation date (newest first)
    memories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    debugPrint('📚 Mock: Retrieved ${memories.length} memories for character: $characterId');
    return memories;
  }

  @override
  Future<List<CharacterMemoryModel>> searchSimilarMemories({
    required String characterId,
    required List<double> queryEmbedding,
    int limit = 10,
    double minSimilarity = 0.0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200)); // Simulate vector search
    
    final characterMemories = await getCharacterMemories(characterId);
    
    // Mock similarity calculation based on content matching
    final searchResults = <MapEntry<CharacterMemoryModel, double>>[];
    
    for (final memory in characterMemories) {
      // Simple mock similarity: check if query vector has similar values
      double similarity = _calculateMockSimilarity(memory.embedding, queryEmbedding);
      
      if (similarity >= minSimilarity) {
        searchResults.add(MapEntry(memory, similarity));
      }
    }
    
    // Sort by similarity (highest first)
    searchResults.sort((a, b) => b.value.compareTo(a.value));
    
    final results = searchResults
        .take(limit)
        .map((entry) => entry.key.withSimilarity(entry.value))
        .toList();
    
    debugPrint('🔍 Mock: Found ${results.length} similar memories for character: $characterId');
    return results;
  }

  @override
  Future<List<CharacterMemoryModel>> searchMemoriesByText({
    required String characterId,
    required String query,
    int limit = 10,
    double minSimilarity = 0.0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    
    final characterMemories = await getCharacterMemories(characterId);
    final queryLower = query.toLowerCase();
    
    // Mock text search: simple keyword matching
    final searchResults = <MapEntry<CharacterMemoryModel, double>>[];
    
    for (final memory in characterMemories) {
      double similarity = _calculateTextSimilarity(memory.content, queryLower);
      
      if (similarity >= minSimilarity) {
        searchResults.add(MapEntry(memory, similarity));
      }
    }
    
    // Sort by similarity (highest first)
    searchResults.sort((a, b) => b.value.compareTo(a.value));
    
    final results = searchResults
        .take(limit)
        .map((entry) => entry.key.withSimilarity(entry.value))
        .toList();
    
    debugPrint('🔍 Mock: Found ${results.length} memories by text for character: $characterId');
    return results;
  }

  @override
  Future<List<CharacterMemoryModel>> getMemoriesByType({
    required String characterId,
    required String contentType,
    int limit = 50,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    final characterMemories = await getCharacterMemories(characterId);
    
    final results = characterMemories
        .where((memory) => memory.contentType == contentType)
        .take(limit)
        .toList();
    
    debugPrint('📊 Mock: Found ${results.length} memories of type "$contentType" for character: $characterId');
    return results;
  }

  @override
  Future<CharacterMemoryModel?> getMemoryById(String memoryId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    
    final memory = _memories[memoryId];
    debugPrint('🔍 Mock: Get memory by ID: $memoryId - ${memory != null ? "Found" : "Not found"}');
    return memory;
  }

  @override
  Future<void> deleteAllCharacterMemories(String characterId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    final memoriesToDelete = _memories.keys
        .where((key) => _memories[key]!.characterId == characterId)
        .toList();
    
    for (final key in memoriesToDelete) {
      _memories.remove(key);
    }
    
    debugPrint('🗑️ Mock: Deleted ${memoriesToDelete.length} memories for character: $characterId');
  }

  @override
  Future<bool> isHealthy() async {
    await Future.delayed(const Duration(milliseconds: 10));
    return true; // Mock is always healthy
  }

  /// Calculate mock similarity between two embeddings
  double _calculateMockSimilarity(List<double> embedding1, List<double> embedding2) {
    if (embedding1.isEmpty || embedding2.isEmpty) {
      return 0.5; // Default similarity for mock embeddings
    }
    
    // Simple mock calculation: average of first few values
    final maxLength = 10; // Only compare first 10 values for performance
    final length = [embedding1.length, embedding2.length, maxLength].reduce((a, b) => a < b ? a : b);
    
    double sum = 0.0;
    for (int i = 0; i < length; i++) {
      final diff = (embedding1[i] - embedding2[i]).abs();
      sum += 1.0 - (diff / 2.0).clamp(0.0, 1.0); // Normalize to 0-1
    }
    
    return (sum / length).clamp(0.0, 1.0);
  }

  /// Calculate text similarity based on keyword matching
  double _calculateTextSimilarity(String content, String queryLower) {
    final contentLower = content.toLowerCase();
    
    // Exact match gets highest score
    if (contentLower.contains(queryLower)) {
      return 0.9;
    }
    
    // Split into words and check for word matches
    final queryWords = queryLower.split(' ').where((w) => w.length > 2).toList();
    final contentWords = contentLower.split(' ');
    
    if (queryWords.isEmpty) {
      return 0.1;
    }
    
    int matches = 0;
    for (final queryWord in queryWords) {
      if (contentWords.any((word) => word.contains(queryWord))) {
        matches++;
      }
    }
    
    final similarity = matches / queryWords.length;
    
    // Add small bonus for longer content (might have more context)
    final lengthBonus = (content.length / 1000.0).clamp(0.0, 0.1);
    
    return (similarity + lengthBonus).clamp(0.0, 1.0);
  }
} 
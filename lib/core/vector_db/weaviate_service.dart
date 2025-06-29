import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:critchat/features/characters/domain/entities/character_memory_entity.dart';

class WeaviateConfig {
  final String url;
  final String? apiKey;
  final String className;

  const WeaviateConfig({
    required this.url,
    this.apiKey,
    this.className = 'CharacterMemory',
  });
}

class WeaviateService {
  final WeaviateConfig config;
  final http.Client httpClient;

  WeaviateService({
    required this.config,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  /// Initialize the Weaviate schema
  Future<void> initializeSchema() async {
    try {
      debugPrint('🔧 Initializing Weaviate schema...');
      
      final schema = {
        'class': config.className,
        'description': 'Character memories and knowledge for RAG system',
        'vectorizer': 'none', // We provide our own vectors
        'properties': [
          {
            'name': 'characterId',
            'dataType': ['text'],
            'description': 'ID of the character this memory belongs to',
          },
          {
            'name': 'userId',
            'dataType': ['text'],
            'description': 'ID of the user who owns this character',
          },
          {
            'name': 'content',
            'dataType': ['text'],
            'description': 'The actual text content of the memory',
          },
          {
            'name': 'contentType',
            'dataType': ['text'],
            'description': 'Type of content (session, npc_interaction, journal, etc.)',
          },
          {
            'name': 'source',
            'dataType': ['text'],
            'description': 'Source of the memory (optional)',
          },
          {
            'name': 'metadata',
            'dataType': ['text'],
            'description': 'JSON string of additional metadata',
          },
          {
            'name': 'createdAt',
            'dataType': ['date'],
            'description': 'When this memory was created',
          },
          {
            'name': 'updatedAt',
            'dataType': ['date'],
            'description': 'When this memory was last updated',
          },
        ],
      };

      final response = await _makeRequest(
        'POST',
        '/v1/schema',
        body: schema,
      );

      if (response.statusCode == 200 || response.statusCode == 422) {
        // 422 means class already exists, which is fine
        debugPrint('✅ Weaviate schema initialized successfully');
      } else {
        throw Exception('Failed to initialize schema: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize Weaviate schema: $e');
      throw Exception('Failed to initialize Weaviate schema: $e');
    }
  }

  /// Store a character memory in Weaviate
  Future<String> storeMemory(CharacterMemoryEntity memory) async {
    try {
      debugPrint('📝 Storing memory in Weaviate for character: ${memory.characterId}');

      final object = {
        'class': config.className,
        'properties': {
          'characterId': memory.characterId,
          'userId': memory.userId,
          'content': memory.content,
          'contentType': memory.contentType,
          'source': memory.source ?? '',
          'metadata': jsonEncode(memory.metadata),
          'createdAt': memory.createdAt.toIso8601String(),
          'updatedAt': memory.updatedAt.toIso8601String(),
        },
        'vector': memory.embedding,
      };

      final response = await _makeRequest(
        'POST',
        '/v1/objects',
        body: object,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final id = responseData['id'] as String;
        debugPrint('✅ Memory stored with ID: $id');
        return id;
      } else {
        throw Exception('Failed to store memory: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Failed to store memory in Weaviate: $e');
      throw Exception('Failed to store memory in Weaviate: $e');
    }
  }

  /// Search for similar memories using vector similarity
  Future<List<Map<String, dynamic>>> searchSimilarMemories({
    required String characterId,
    required List<double> queryVector,
    int limit = 10,
    double minSimilarity = 0.0,
  }) async {
    try {
      debugPrint('🔍 Searching for similar memories for character: $characterId');

      final query = {
        'query': '''
        {
          Get {
            ${config.className}(
              where: {
                path: ["characterId"]
                operator: Equal
                valueText: "$characterId"
              }
              nearVector: {
                vector: ${jsonEncode(queryVector)}
                certainty: ${(minSimilarity + 1) / 2} 
              }
              limit: $limit
            ) {
              _additional {
                id
                certainty
                distance
              }
              characterId
              userId
              content
              contentType
              source
              metadata
              createdAt
              updatedAt
            }
          }
        }
        ''',
      };

      final response = await _makeRequest(
        'POST',
        '/v1/graphql',
        body: query,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final memories = responseData['data']['Get'][config.className] as List;
        
        debugPrint('✅ Found ${memories.length} similar memories');
        return memories.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to search memories: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Failed to search memories in Weaviate: $e');
      throw Exception('Failed to search memories in Weaviate: $e');
    }
  }

  /// Get all memories for a character
  Future<List<Map<String, dynamic>>> getCharacterMemories(String characterId) async {
    try {
      debugPrint('📚 Getting all memories for character: $characterId');

      final query = {
        'query': '''
        {
          Get {
            ${config.className}(
              where: {
                path: ["characterId"]
                operator: Equal
                valueText: "$characterId"
              }
              limit: 1000
            ) {
              _additional {
                id
              }
              characterId
              userId
              content
              contentType
              source
              metadata
              createdAt
              updatedAt
            }
          }
        }
        ''',
      };

      final response = await _makeRequest(
        'POST',
        '/v1/graphql',
        body: query,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final memories = responseData['data']['Get'][config.className] as List;
        
        debugPrint('✅ Retrieved ${memories.length} memories for character');
        return memories.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to get character memories: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Failed to get character memories from Weaviate: $e');
      throw Exception('Failed to get character memories from Weaviate: $e');
    }
  }

  /// Delete a memory by ID
  Future<void> deleteMemory(String memoryId) async {
    try {
      debugPrint('🗑️ Deleting memory: $memoryId');

      final response = await _makeRequest(
        'DELETE',
        '/v1/objects/$memoryId',
      );

      if (response.statusCode == 204) {
        debugPrint('✅ Memory deleted successfully');
      } else if (response.statusCode == 404) {
        debugPrint('⚠️ Memory not found (may already be deleted)');
      } else {
        throw Exception('Failed to delete memory: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Failed to delete memory from Weaviate: $e');
      throw Exception('Failed to delete memory from Weaviate: $e');
    }
  }

  /// Delete all memories for a character
  Future<void> deleteAllCharacterMemories(String characterId) async {
    try {
      debugPrint('🗑️ Deleting all memories for character: $characterId');

      final query = {
        'query': '''
        mutation {
          BatchDelete(
            match: {
              class: "${config.className}"
              where: {
                path: ["characterId"]
                operator: Equal
                valueText: "$characterId"
              }
            }
          ) {
            successful
            failed
          }
        }
        ''',
      };

      final response = await _makeRequest(
        'POST',
        '/v1/graphql',
        body: query,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final batchResult = responseData['data']['BatchDelete'];
        debugPrint('✅ Deleted memories - successful: ${batchResult['successful']}, failed: ${batchResult['failed']}');
      } else {
        throw Exception('Failed to delete character memories: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Failed to delete character memories from Weaviate: $e');
      throw Exception('Failed to delete character memories from Weaviate: $e');
    }
  }

  /// Check if Weaviate is healthy and accessible
  Future<bool> isHealthy() async {
    try {
      final response = await _makeRequest('GET', '/v1/meta');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('🔍 Weaviate health check failed: $e');
      return false;
    }
  }

  /// Make HTTP request to Weaviate
  Future<http.Response> _makeRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${config.url}$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (config.apiKey != null) {
      headers['Authorization'] = 'Bearer ${config.apiKey}';
    }

    http.Response response;
    switch (method.toUpperCase()) {
      case 'GET':
        response = await httpClient.get(uri, headers: headers);
        break;
      case 'POST':
        response = await httpClient.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'DELETE':
        response = await httpClient.delete(uri, headers: headers);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    return response;
  }

  /// Dispose resources
  void dispose() {
    httpClient.close();
  }
} 
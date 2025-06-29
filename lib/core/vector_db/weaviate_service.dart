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

  /// Format DateTime to RFC3339 string that Weaviate expects
  String _formatDateTimeForWeaviate(DateTime dateTime) {
    final utcDateTime = dateTime.toUtc();
    final isoString = utcDateTime.toIso8601String();
    // Ensure it ends with 'Z' for UTC timezone
    return isoString.endsWith('Z') ? isoString : '${isoString}Z';
  }

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
          'createdAt': _formatDateTimeForWeaviate(memory.createdAt),
          'updatedAt': _formatDateTimeForWeaviate(memory.updatedAt),
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

  /// Initialize the LFG Posts schema in Weaviate
  Future<void> initializeLfgSchema() async {
    try {
      debugPrint('🔧 Initializing Weaviate LFG schema...');
      
      final schema = {
        'class': 'LfgPost',
        'description': 'Looking for Group posts for semantic matching',
        'vectorizer': 'none', // We provide our own vectors
        'properties': [
          {
            'name': 'postId',
            'dataType': ['text'],
            'description': 'ID of the LFG post',
          },
          {
            'name': 'userId',
            'dataType': ['text'],
            'description': 'ID of the user who created this post',
          },
          {
            'name': 'userName',
            'dataType': ['text'],
            'description': 'Name of the user who created this post',
          },
          {
            'name': 'userLevel',
            'dataType': ['int'],
            'description': 'Level of the user who created this post',
          },
          {
            'name': 'content',
            'dataType': ['text'],
            'description': 'The searchable content of the LFG post',
          },
          {
            'name': 'gameSystem',
            'dataType': ['text'],
            'description': 'Game system for this post',
          },
          {
            'name': 'playStyles',
            'dataType': ['text[]'],
            'description': 'Play styles for this post',
          },
          {
            'name': 'sessionFormat',
            'dataType': ['text'],
            'description': 'Session format preference',
          },
          {
            'name': 'schedulePreference',
            'dataType': ['text'],
            'description': 'Schedule preference',
          },
          {
            'name': 'campaignLength',
            'dataType': ['text'],
            'description': 'Campaign length preference',
          },
          {
            'name': 'callToAdventureText',
            'dataType': ['text'],
            'description': 'The main call to adventure text',
          },
          {
            'name': 'isClosed',
            'dataType': ['boolean'],
            'description': 'Whether this post is closed',
          },
          {
            'name': 'createdAt',
            'dataType': ['date'],
            'description': 'When this post was created',
          },
          {
            'name': 'updatedAt',
            'dataType': ['date'],
            'description': 'When this post was last updated',
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
        debugPrint('✅ Weaviate LFG schema initialized successfully');
      } else {
        throw Exception('Failed to initialize LFG schema: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize Weaviate LFG schema: $e');
      throw Exception('Failed to initialize Weaviate LFG schema: $e');
    }
  }

  /// Store an LFG post in Weaviate
  Future<String> storeLfgPost({
    required String postId,
    required String userId,
    required String userName,
    required int userLevel,
    required String content,
    required String gameSystem,
    required List<String> playStyles,
    required String sessionFormat,
    required String schedulePreference,
    required String campaignLength,
    required String callToAdventureText,
    required bool isClosed,
    required DateTime createdAt,
    required DateTime updatedAt,
    required List<double> embedding,
  }) async {
    try {
      debugPrint('📝 Storing LFG post in Weaviate: $postId');

      final object = {
        'class': 'LfgPost',
        'properties': {
          'postId': postId,
          'userId': userId,
          'userName': userName,
          'userLevel': userLevel,
          'content': content,
          'gameSystem': gameSystem,
          'playStyles': playStyles,
          'sessionFormat': sessionFormat,
          'schedulePreference': schedulePreference,
          'campaignLength': campaignLength,
          'callToAdventureText': callToAdventureText,
          'isClosed': isClosed,
          'createdAt': _formatDateTimeForWeaviate(createdAt),
          'updatedAt': _formatDateTimeForWeaviate(updatedAt),
        },
        'vector': embedding,
      };

      final response = await _makeRequest(
        'POST',
        '/v1/objects',
        body: object,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final id = responseData['id'] as String;
        debugPrint('✅ LFG post stored with ID: $id');
        return id;
      } else {
        throw Exception('Failed to store LFG post: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Failed to store LFG post in Weaviate: $e');
      throw Exception('Failed to store LFG post in Weaviate: $e');
    }
  }

  /// Search for similar LFG posts using vector similarity
  Future<List<Map<String, dynamic>>> searchSimilarLfgPosts({
    required List<double> queryVector,
    int limit = 10,
    double minSimilarity = 0.0,
  }) async {
    try {
      debugPrint('🔍 Searching for similar LFG posts');

      final query = {
        'query': '''
        {
          Get {
            LfgPost(
              where: {
                path: ["isClosed"]
                operator: Equal
                valueBoolean: false
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
              postId
              userId
              userName
              userLevel
              content
              gameSystem
              playStyles
              sessionFormat
              schedulePreference
              campaignLength
              callToAdventureText
              isClosed
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
        final posts = responseData['data']['Get']['LfgPost'] as List;
        
        debugPrint('✅ Found ${posts.length} similar LFG posts');
        return posts.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to search LFG posts: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Failed to search LFG posts in Weaviate: $e');
      throw Exception('Failed to search LFG posts in Weaviate: $e');
    }
  }

  /// Delete an LFG post from Weaviate
  Future<void> deleteLfgPost(String postId) async {
    try {
      debugPrint('🗑️ Deleting LFG post from Weaviate: $postId');

      // First, find the Weaviate object ID for this post
      final query = {
        'query': '''
        {
          Get {
            LfgPost(
              where: {
                path: ["postId"]
                operator: Equal
                valueText: "$postId"
              }
              limit: 1
            ) {
              _additional {
                id
              }
            }
          }
        }
        ''',
      };

      final searchResponse = await _makeRequest(
        'POST',
        '/v1/graphql',
        body: query,
      );

      if (searchResponse.statusCode == 200) {
        final responseData = jsonDecode(searchResponse.body);
        final posts = responseData['data']['Get']['LfgPost'] as List;
        
        if (posts.isNotEmpty) {
          final weaviateId = posts.first['_additional']['id'] as String;
          
          // Delete the object
          final deleteResponse = await _makeRequest(
            'DELETE',
            '/v1/objects/$weaviateId',
          );

          if (deleteResponse.statusCode == 204) {
            debugPrint('✅ LFG post deleted from Weaviate: $postId');
          } else {
            throw Exception('Failed to delete LFG post: ${deleteResponse.body}');
          }
        } else {
          debugPrint('⚠️ LFG post not found in Weaviate: $postId');
        }
      } else {
        throw Exception('Failed to find LFG post for deletion: ${searchResponse.body}');
      }
    } catch (e) {
      debugPrint('❌ Failed to delete LFG post from Weaviate: $e');
      throw Exception('Failed to delete LFG post from Weaviate: $e');
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
import 'package:critchat/features/lfg/data/models/lfg_post_model.dart';
import 'package:critchat/core/vector_db/weaviate_service.dart';
import 'package:critchat/core/embeddings/embedding_service.dart';
import 'package:critchat/features/characters/domain/entities/character_memory_entity.dart';
import 'package:flutter/foundation.dart';


abstract class LfgRagDataSource {
  Future<void> indexLfgPost(LfgPostModel post);
  Future<List<LfgPostModel>> searchSimilarPosts(String query, List<LfgPostModel> posts);
  Future<void> deleteLfgPostIndex(String postId);
  Future<bool> isHealthy();
}

class LfgRagDataSourceImpl implements LfgRagDataSource {
  final WeaviateService _weaviateService;
  final EmbeddingService _embeddingService;
  


  LfgRagDataSourceImpl({
    required WeaviateService weaviateService,
    required EmbeddingService embeddingService,
  }) : _weaviateService = weaviateService,
       _embeddingService = embeddingService;

  @override
  Future<void> indexLfgPost(LfgPostModel post) async {
    try {
      debugPrint('📝 Indexing LFG post: ${post.id}');

      // Create indexable content from the post
      final indexableContent = _createIndexableContent(post);

      // Generate embedding for the content
      final embedding = await _embeddingService.generateEmbedding(indexableContent);

      // Store in Weaviate
      await _storeLfgPostInWeaviate(post, embedding, indexableContent);

      debugPrint('✅ LFG post indexed successfully: ${post.id}');
    } catch (e) {
      debugPrint('❌ Failed to index LFG post ${post.id}: $e');
      throw Exception('Failed to index LFG post: $e');
    }
  }

  @override
  Future<List<LfgPostModel>> searchSimilarPosts(String query, List<LfgPostModel> posts) async {
    try {
      debugPrint('🔍 Searching similar LFG posts for query: $query');

      // Generate embedding for the query
      final queryEmbedding = await _embeddingService.generateEmbedding(query);

      // Search in Weaviate
      final searchResults = await _searchSimilarInWeaviate(queryEmbedding);

      // Match results with provided posts and add similarity scores
      final scoredPosts = _matchPostsWithSimilarity(posts, searchResults);

      debugPrint('✅ Found ${scoredPosts.length} similar posts');
      return scoredPosts;
    } catch (e) {
      debugPrint('❌ Failed to search similar posts: $e');
      // Return original posts without similarity scores on error
      return posts;
    }
  }

  @override
  Future<void> deleteLfgPostIndex(String postId) async {
    try {
      debugPrint('🗑️ Deleting LFG post index: $postId');
      await _weaviateService.deleteMemory(postId);
      debugPrint('✅ LFG post index deleted: $postId');
    } catch (e) {
      debugPrint('❌ Failed to delete LFG post index $postId: $e');
      throw Exception('Failed to delete LFG post index: $e');
    }
  }

  @override
  Future<bool> isHealthy() async {
    try {
      return await _weaviateService.isHealthy();
    } catch (e) {
      debugPrint('🔍 LFG RAG datasource health check failed: $e');
      return false;
    }
  }

  /// Create indexable content from LFG post
  String _createIndexableContent(LfgPostModel post) {
    final content = StringBuffer();
    
    // Add game system
    content.writeln('Game System: ${post.gameSystem}');
    
    // Add play styles
    content.writeln('Play Styles: ${post.playStyles.join(', ')}');
    
    // Add session format
    content.writeln('Session Format: ${post.sessionFormat}');
    
    // Add schedule preference
    content.writeln('Schedule: ${post.schedulePreference}');
    
    // Add campaign length
    content.writeln('Campaign Length: ${post.campaignLength}');
    
    // Add the main call to adventure text (most important for semantic matching)
    content.writeln('Call to Adventure: ${post.callToAdventureText}');
    
    return content.toString();
  }

  /// Store LFG post in Weaviate using the character memory interface
  Future<void> _storeLfgPostInWeaviate(
    LfgPostModel post,
    List<double> embedding,
    String indexableContent,
  ) async {
    // Note: Using CharacterMemoryEntity structure to work with existing service
    // This is a workaround - ideally we'd have a generic storage service
    final memoryEntity = CharacterMemoryEntity(
      id: post.id,
      characterId: 'lfg_post_${post.id}', // Use a unique character ID for LFG posts
      userId: post.userId,
      content: indexableContent,
      source: 'lfg_system',
      metadata: {
        'type': 'lfg_post', // Content type is set via metadata
        'postId': post.id,
        'userName': post.userName,
        'userLevel': post.userLevel,
        'gameSystem': post.gameSystem,
        'playStyles': post.playStyles,
        'sessionFormat': post.sessionFormat,
        'schedulePreference': post.schedulePreference,
        'campaignLength': post.campaignLength,
        'callToAdventureText': post.callToAdventureText,
        'isClosed': post.isClosed,
      },
      embedding: embedding,
      createdAt: post.createdAt,
      updatedAt: post.lastRefreshed ?? post.createdAt,
    );

    await _weaviateService.storeMemory(memoryEntity);
  }

  /// Search for similar posts in Weaviate using character memory search
  Future<List<Map<String, dynamic>>> _searchSimilarInWeaviate(
    List<double> queryEmbedding,
  ) async {
    // Use character memory search with a special "character ID" for LFG posts
    // This is a workaround - ideally we'd have a generic search service
    try {
      return await _weaviateService.searchSimilarMemories(
        characterId: 'lfg_posts', // Search all LFG posts
        queryVector: queryEmbedding,
        limit: 50,
        minSimilarity: 0.1,
      );
    } catch (e) {
      debugPrint('⚠️ Weaviate search failed, returning empty results: $e');
      return [];
    }
  }

  /// Match posts with similarity scores from Weaviate results
  List<LfgPostModel> _matchPostsWithSimilarity(
    List<LfgPostModel> posts,
    List<Map<String, dynamic>> searchResults,
  ) {
    final scoredPosts = <LfgPostModel>[];

    for (final post in posts) {
      // Find matching result from Weaviate
      final matchingResult = searchResults.where(
        (result) => result['postId'] == post.id,
      ).firstOrNull;

      if (matchingResult != null) {
        // Extract similarity score (certainty in Weaviate)
        final certainty = matchingResult['_additional']?['certainty'] as double?;
        final similarityScore = certainty ?? 0.0;

        // Add post with similarity score
        scoredPosts.add(post.copyWith(matchScore: similarityScore));
      } else {
        // Add post without similarity score
        scoredPosts.add(post);
      }
    }

    return scoredPosts;
  }
}

/// Mock implementation for development/testing
class LfgRagMockDataSource implements LfgRagDataSource {
  @override
  Future<void> indexLfgPost(LfgPostModel post) async {
    // Simulate indexing delay
    await Future.delayed(const Duration(milliseconds: 100));
    debugPrint('📝 [MOCK] Indexed LFG post: ${post.id}');
  }

  @override
  Future<List<LfgPostModel>> searchSimilarPosts(String query, List<LfgPostModel> posts) async {
    // Simulate search delay
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Simple mock semantic matching based on keywords
    final queryLower = query.toLowerCase();
    final scoredPosts = <LfgPostModel>[];

    for (final post in posts) {
      double score = 0.0;
      
      // Check game system match
      if (post.gameSystem.toLowerCase().contains(queryLower)) {
        score += 0.3;
      }
      
      // Check play styles match
      for (final style in post.playStyles) {
        if (style.toLowerCase().contains(queryLower)) {
          score += 0.2;
        }
      }
      
      // Check call to adventure text match
      if (post.callToAdventureText.toLowerCase().contains(queryLower)) {
        score += 0.4;
      }
      
      // Check session format match
      if (post.sessionFormat.toLowerCase().contains(queryLower)) {
        score += 0.1;
      }
      
      // Add some randomness to simulate semantic similarity
      score += (DateTime.now().millisecond % 20) / 100.0;
      
      scoredPosts.add(post.copyWith(matchScore: score.clamp(0.0, 1.0)));
    }

    debugPrint('🔍 [MOCK] Generated similarity scores for ${posts.length} posts');
    return scoredPosts;
  }

  @override
  Future<void> deleteLfgPostIndex(String postId) async {
    // Simulate deletion delay
    await Future.delayed(const Duration(milliseconds: 50));
    debugPrint('🗑️ [MOCK] Deleted LFG post index: $postId');
  }

  @override
  Future<bool> isHealthy() async {
    return true; // Mock is always healthy
  }
} 
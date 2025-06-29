import 'package:critchat/features/lfg/data/models/lfg_post_model.dart';
import 'package:critchat/core/vector_db/weaviate_service.dart';
import 'package:critchat/core/embeddings/embedding_service.dart';
import 'package:flutter/foundation.dart';


abstract class LfgRagDataSource {
  Future<void> initializeSchema();
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
  Future<void> initializeSchema() async {
    try {
      debugPrint('🔧 Initializing LFG schema...');
      await _weaviateService.initializeLfgSchema();
      debugPrint('✅ LFG schema initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize LFG schema: $e');
      throw Exception('Failed to initialize LFG schema: $e');
    }
  }

  @override
  Future<void> indexLfgPost(LfgPostModel post) async {
    try {
      debugPrint('📝 Indexing LFG post: ${post.id}');

      // Create indexable content from the post
      final indexableContent = _createIndexableContent(post);

      // Generate embedding for the content
      final embedding = await _embeddingService.generateEmbedding(indexableContent);

      // Store in Weaviate using the new LFG-specific method
      await _weaviateService.storeLfgPost(
        postId: post.id,
        userId: post.userId,
        userName: post.userName,
        userLevel: post.userLevel,
        content: indexableContent,
        gameSystem: post.gameSystem,
        playStyles: post.playStyles,
        sessionFormat: post.sessionFormat,
        schedulePreference: post.schedulePreference,
        campaignLength: post.campaignLength,
        callToAdventureText: post.callToAdventureText,
        isClosed: post.isClosed,
        createdAt: post.createdAt,
        updatedAt: post.lastRefreshed ?? post.createdAt,
        embedding: embedding,
      );

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

      // Search in Weaviate using the new LFG-specific method
      final searchResults = await _weaviateService.searchSimilarLfgPosts(
        queryVector: queryEmbedding,
        limit: 50,
        minSimilarity: 0.1,
      );

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
      await _weaviateService.deleteLfgPost(postId);
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

class LfgRagMockDataSource implements LfgRagDataSource {
  @override
  Future<void> initializeSchema() async {
    debugPrint('ℹ️ Mock LFG RAG datasource - schema initialization skipped');
  }

  @override
  Future<void> indexLfgPost(LfgPostModel post) async {
    debugPrint('ℹ️ Mock LFG RAG datasource - indexing post ${post.id} (skipped)');
  }

  @override
  Future<List<LfgPostModel>> searchSimilarPosts(String query, List<LfgPostModel> posts) async {
    debugPrint('ℹ️ Mock LFG RAG datasource - returning posts without similarity scores');
    return posts;
  }

  @override
  Future<void> deleteLfgPostIndex(String postId) async {
    debugPrint('ℹ️ Mock LFG RAG datasource - deleting post $postId (skipped)');
  }

  @override
  Future<bool> isHealthy() async {
    return true;
  }
} 
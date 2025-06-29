import 'package:critchat/features/lfg/domain/entities/lfg_post_entity.dart';
import 'package:critchat/features/lfg/domain/repositories/lfg_repository.dart';
import 'package:critchat/features/lfg/data/datasources/lfg_firestore_datasource.dart';
import 'package:critchat/features/lfg/data/datasources/lfg_mock_datasource.dart';
import 'package:critchat/features/lfg/data/datasources/lfg_rag_datasource.dart';
import 'package:critchat/features/lfg/data/models/lfg_post_model.dart';
import 'package:critchat/features/lfg/data/services/lfg_matching_service.dart';
import 'package:critchat/core/config/rag_config.dart';
import 'package:flutter/foundation.dart';

class LfgRepositoryImpl implements LfgRepository {
  final LfgFirestoreDataSource? _firestoreDataSource;
  final LfgMockDataSource? _mockDataSource;
  final LfgRagDataSource? _ragDataSource;
  final LfgMatchingService _matchingService;
  final RagConfig _ragConfig;

  LfgRepositoryImpl({
    LfgFirestoreDataSource? firestoreDataSource,
    LfgMockDataSource? mockDataSource,
    LfgRagDataSource? ragDataSource,
    required LfgMatchingService matchingService,
    required RagConfig ragConfig,
  }) : _firestoreDataSource = firestoreDataSource,
       _mockDataSource = mockDataSource,
       _ragDataSource = ragDataSource,
       _matchingService = matchingService,
       _ragConfig = ragConfig;

  /// Initialize the repository and its dependencies
  Future<void> initialize() async {
    try {
      debugPrint('🔧 Initializing LFG Repository...');
      
      // Initialize RAG schema if RAG datasource is available
      if (_ragDataSource != null) {
        await _ragDataSource.initializeSchema();
        debugPrint('✅ LFG RAG schema initialized');
      } else {
        debugPrint('ℹ️ No RAG datasource available, skipping schema initialization');
      }
      
      debugPrint('✅ LFG Repository initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Failed to initialize LFG Repository: $e');
      // Don't throw - let the app continue without RAG functionality
    }
  }

  /// Get the appropriate datasource based on configuration
  dynamic get _dataSource {
    if (_ragConfig.useMockServices) {
      return _mockDataSource;
    } else {
      return _firestoreDataSource;
    }
  }

  @override
  Future<List<LfgPostEntity>> getActiveLfgPosts(String currentUserId) async {
    try {
      final posts = await _dataSource.getActiveLfgPosts() as List<LfgPostModel>;
      
      // If no posts returned (empty collection or Firestore issues), return empty list
      if (posts.isEmpty) {
        debugPrint('📭 No LFG posts found, returning empty list');
        return [];
      }
      
      // Filter out current user's posts
      final othersPosts = posts.where((post) => post.userId != currentUserId).toList();
      
      debugPrint('🔍 Repository filtering: ${posts.length} total posts, ${othersPosts.length} after filtering (excluding own posts)');
      
      // If user has any posts, get their latest post for matching
      final userPosts = posts.where((post) => post.userId == currentUserId).toList();
      if (userPosts.isNotEmpty) {
        final userLatestPost = userPosts.first; // Already ordered by createdAt desc
        
        // Rank posts by match using our matching service
        final rankedPosts = await _matchingService.rankPostsByMatch(
          othersPosts,
          userLatestPost,
        );
        
        return rankedPosts;
      }
      
      // If user has no posts, return all posts without match scoring
      return othersPosts;
    } catch (e) {
      debugPrint('❌ Failed to get active LFG posts: $e');
      
      // For specific Firestore errors, let them bubble up for the BLoC to handle gracefully
      if (e.toString().contains('index') || e.toString().contains('failed-precondition')) {
        rethrow; // Let BLoC handle this as empty state
      }
      
      throw Exception('Failed to get active LFG posts: $e');
    }
  }

  @override
  Future<List<LfgPostEntity>> getUserLfgPosts(String userId) async {
    try {
      final posts = await _dataSource.getUserLfgPosts(userId) as List<LfgPostModel>;
      return posts;
    } catch (e) {
      debugPrint('❌ Failed to get user LFG posts: $e');
      throw Exception('Failed to get user LFG posts: $e');
    }
  }

  @override
  Future<LfgPostEntity> createLfgPost(LfgPostEntity post) async {
    try {
      final postModel = LfgPostModel.fromEntity(post);
      final createdPost = await _dataSource.createLfgPost(postModel) as LfgPostModel;
      
      // Index the post in RAG system if available
      if (_ragDataSource != null) {
        try {
          await _ragDataSource.indexLfgPost(createdPost);
          debugPrint('✅ LFG post indexed in RAG system: ${createdPost.id}');
        } catch (e) {
          debugPrint('⚠️ Failed to index LFG post in RAG system: $e');
          // Don't fail the creation if RAG indexing fails
        }
      }
      
      return createdPost;
    } catch (e) {
      debugPrint('❌ Failed to create LFG post: $e');
      throw Exception('Failed to create LFG post: $e');
    }
  }

  @override
  Future<LfgPostEntity> updateLfgPost(LfgPostEntity post) async {
    try {
      final postModel = LfgPostModel.fromEntity(post);
      final updatedPost = await _dataSource.updateLfgPost(postModel) as LfgPostModel;
      
      // Update the post in RAG system if available
      if (_ragDataSource != null) {
        try {
          await _ragDataSource.indexLfgPost(updatedPost);
          debugPrint('✅ LFG post updated in RAG system: ${updatedPost.id}');
        } catch (e) {
          debugPrint('⚠️ Failed to update LFG post in RAG system: $e');
          // Don't fail the update if RAG indexing fails
        }
      }
      
      return updatedPost;
    } catch (e) {
      debugPrint('❌ Failed to update LFG post: $e');
      throw Exception('Failed to update LFG post: $e');
    }
  }

  @override
  Future<bool> expressInterest(String postId, String userId) async {
    try {
      await _dataSource.expressInterest(postId, userId);
      return true;
    } catch (e) {
      debugPrint('❌ Failed to express interest: $e');
      return false;
    }
  }

  @override
  Future<bool> closeLfgPost(String postId) async {
    try {
      await _dataSource.closeLfgPost(postId);
      return true;
    } catch (e) {
      debugPrint('❌ Failed to close LFG post: $e');
      return false;
    }
  }

  @override
  Future<LfgPostEntity> refreshLfgPost(String postId) async {
    try {
      final refreshedPost = await _dataSource.refreshLfgPost(postId) as LfgPostModel;
      return refreshedPost;
    } catch (e) {
      debugPrint('❌ Failed to refresh LFG post: $e');
      throw Exception('Failed to refresh LFG post: $e');
    }
  }

  @override
  Future<bool> deleteLfgPost(String postId) async {
    try {
      await _dataSource.deleteLfgPost(postId);
      
      // Remove from RAG system if available
      if (_ragDataSource != null) {
        try {
          await _ragDataSource.deleteLfgPostIndex(postId);
          debugPrint('✅ LFG post removed from RAG system: $postId');
        } catch (e) {
          debugPrint('⚠️ Failed to remove LFG post from RAG system: $e');
          // Don't fail the deletion if RAG removal fails
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Failed to delete LFG post: $e');
      return false;
    }
  }

  @override
  Stream<List<LfgPostEntity>> getLfgPostsStream() {
    try {
      return _dataSource.getLfgPostsStream() as Stream<List<LfgPostEntity>>;
    } catch (e) {
      debugPrint('❌ Failed to get LFG posts stream: $e');
      throw Exception('Failed to get LFG posts stream: $e');
    }
  }

  @override
  Future<int> getUserActivePostCount(String userId) async {
    try {
      return await _dataSource.getUserActivePostCount(userId) as int;
    } catch (e) {
      debugPrint('❌ Failed to get user active post count: $e');
      throw Exception('Failed to get user active post count: $e');
    }
  }
} 
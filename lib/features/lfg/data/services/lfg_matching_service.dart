import 'package:critchat/features/lfg/domain/entities/lfg_post_entity.dart';
import 'package:critchat/features/lfg/data/datasources/lfg_rag_datasource.dart';
import 'package:flutter/foundation.dart';

class LfgMatchingService {
  final LfgRagDataSource? _ragDataSource;

  LfgMatchingService({LfgRagDataSource? ragDataSource}) : _ragDataSource = ragDataSource;

  /// Rank posts by match score based on user's latest post
  /// Priority: Play style alignment > Game system > Campaign length > Schedule > Session format
  Future<List<LfgPostEntity>> rankPostsByMatch(
    List<LfgPostEntity> posts,
    LfgPostEntity userPost,
  ) async {
    if (posts.isEmpty) return posts;

    try {
      debugPrint('🎯 Ranking ${posts.length} posts by match against user post');

      List<LfgPostEntity> scoredPosts = [];

      // Try semantic matching with RAG if available
      if (_ragDataSource != null) {
        try {
          final semanticQuery = _buildSemanticQuery(userPost);
          final ragResults = await _ragDataSource!.searchSimilarPosts(semanticQuery, posts.cast());
          scoredPosts = ragResults.cast<LfgPostEntity>();
          debugPrint('✅ Applied semantic matching using RAG');
        } catch (e) {
          debugPrint('⚠️ RAG semantic matching failed, using algorithmic matching: $e');
          scoredPosts = posts;
        }
      } else {
        scoredPosts = posts;
      }

      // Apply algorithmic scoring to all posts
      final rankedPosts = scoredPosts.map((post) {
        final algorithmicScore = _calculateAlgorithmicMatch(userPost, post);
        final semanticScore = post.matchScore ?? 0.0;
        
        // Combine semantic and algorithmic scores (weighted toward algorithmic for priority)
        final combinedScore = (algorithmicScore * 0.7) + (semanticScore * 0.3);
        
        return post.copyWith(matchScore: combinedScore);
      }).toList();

      // Sort by match score (highest first)
      rankedPosts.sort((a, b) => (b.matchScore ?? 0.0).compareTo(a.matchScore ?? 0.0));

      debugPrint('✅ Ranked posts with scores ranging from ${rankedPosts.last.matchScore?.toStringAsFixed(2)} to ${rankedPosts.first.matchScore?.toStringAsFixed(2)}');
      
      return rankedPosts;
    } catch (e) {
      debugPrint('❌ Failed to rank posts by match: $e');
      return posts;
    }
  }

  /// Build semantic query for RAG system
  String _buildSemanticQuery(LfgPostEntity userPost) {
    final queryParts = <String>[];
    
    // Add play styles (most important)
    queryParts.addAll(userPost.playStyles);
    
    // Add game system
    queryParts.add(userPost.gameSystem);
    
    // Add key parts of call to adventure
    final callToAdventure = userPost.callToAdventureText;
    if (callToAdventure.length > 50) {
      // Take first 100 characters for semantic matching
      queryParts.add(callToAdventure.substring(0, 100));
    } else {
      queryParts.add(callToAdventure);
    }
    
    return queryParts.join(' ');
  }

  /// Calculate algorithmic match score based on priority criteria
  double _calculateAlgorithmicMatch(LfgPostEntity userPost, LfgPostEntity otherPost) {
    double score = 0.0;
    
    // 1. Play style alignment (40% weight - most important)
    score += _calculatePlayStyleMatch(userPost.playStyles, otherPost.playStyles) * 0.4;
    
    // 2. Game system matches (25% weight)
    score += _calculateGameSystemMatch(userPost.gameSystem, otherPost.gameSystem) * 0.25;
    
    // 3. Campaign length compatibility (20% weight)
    score += _calculateCampaignLengthMatch(userPost.campaignLength, otherPost.campaignLength) * 0.2;
    
    // 4. Schedule overlap (10% weight)
    score += _calculateScheduleMatch(userPost.schedulePreference, otherPost.schedulePreference) * 0.1;
    
    // 5. Session format compatibility (5% weight - least important)
    score += _calculateSessionFormatMatch(userPost.sessionFormat, otherPost.sessionFormat) * 0.05;
    
    return score.clamp(0.0, 1.0);
  }

  /// Calculate play style match score
  double _calculatePlayStyleMatch(List<String> userStyles, List<String> otherStyles) {
    if (userStyles.isEmpty || otherStyles.isEmpty) return 0.0;
    
    final normalizedUserStyles = userStyles.map((s) => s.toLowerCase()).toSet();
    final normalizedOtherStyles = otherStyles.map((s) => s.toLowerCase()).toSet();
    
    // Exact matches get full score
    final exactMatches = normalizedUserStyles.intersection(normalizedOtherStyles).length;
    if (exactMatches > 0) {
      return exactMatches / normalizedUserStyles.length;
    }
    
    // Partial matches for similar styles
    double partialScore = 0.0;
    for (final userStyle in normalizedUserStyles) {
      for (final otherStyle in normalizedOtherStyles) {
        partialScore += _calculateStyleSimilarity(userStyle, otherStyle);
      }
    }
    
    return (partialScore / (normalizedUserStyles.length * normalizedOtherStyles.length)).clamp(0.0, 1.0);
  }

  /// Calculate style similarity for partial matches
  double _calculateStyleSimilarity(String style1, String style2) {
    // Define style relationships
    const styleRelationships = {
      'roleplay-focused': ['political intrigue', 'exploration'],
      'combat-heavy': ['tactical'],
      'exploration': ['roleplay-focused', 'sandbox'],
      'political intrigue': ['roleplay-focused', 'puzzle-solving'],
      'puzzle-solving': ['political intrigue'],
      'sandbox': ['exploration'],
      'tactical': ['combat-heavy'],
      'magic-heavy': ['exploration', 'combat-heavy'],
    };
    
    final related = styleRelationships[style1] ?? [];
    if (related.contains(style2)) {
      return 0.5; // Partial match for related styles
    }
    
    return 0.0;
  }

  /// Calculate game system match score
  double _calculateGameSystemMatch(String userSystem, String otherSystem) {
    final user = userSystem.toLowerCase();
    final other = otherSystem.toLowerCase();
    
    // Exact match
    if (user == other) return 1.0;
    
    // Define system compatibility groups
    const systemGroups = {
      'd&d': ['d&d 5e', 'd&d 3.5e', 'd&d 4e', 'dungeons & dragons'],
      'pathfinder': ['pathfinder 2e', 'pathfinder 1e'],
      'call of cthulhu': ['call of cthulhu 7e', 'call of cthulhu 6e'],
      'vampire': ['vampire: the masquerade', 'vampire: the masquerade 5e'],
      'world of darkness': ['vampire: the masquerade', 'werewolf: the apocalypse'],
    };
    
    // Check for group compatibility
    for (final group in systemGroups.values) {
      if (group.any((system) => user.contains(system)) && 
          group.any((system) => other.contains(system))) {
        return 0.8; // High compatibility within system family
      }
    }
    
    // Partial matches for similar systems
    if ((user.contains('d&d') || user.contains('dungeons')) && 
        (other.contains('pathfinder'))) {
      return 0.6; // D&D and Pathfinder are somewhat compatible
    }
    
    return 0.0;
  }

  /// Calculate campaign length match score
  double _calculateCampaignLengthMatch(String userLength, String otherLength) {
    const lengthOrder = ['one-shot', 'short campaign', 'medium campaign', 'long campaign'];
    
    final userIndex = lengthOrder.indexWhere((l) => userLength.toLowerCase().contains(l));
    final otherIndex = lengthOrder.indexWhere((l) => otherLength.toLowerCase().contains(l));
    
    if (userIndex == -1 || otherIndex == -1) return 0.0;
    
    // Exact match
    if (userIndex == otherIndex) return 1.0;
    
    // Adjacent lengths are somewhat compatible
    if ((userIndex - otherIndex).abs() == 1) return 0.7;
    
    // Distant lengths are less compatible
    if ((userIndex - otherIndex).abs() == 2) return 0.4;
    
    return 0.1; // Very different lengths
  }

  /// Calculate schedule match score
  double _calculateScheduleMatch(String userSchedule, String otherSchedule) {
    final user = userSchedule.toLowerCase();
    final other = otherSchedule.toLowerCase();
    
    // Exact match
    if (user == other) return 1.0;
    
    // Define schedule compatibility
    const scheduleCompatibility = {
      '2/week': ['1/week', '2/week'],
      '1/week': ['2/week', '1/week', '2/month'],
      '2/month': ['1/week', '2/month', '1/month'],
      '1/month': ['2/month', '1/month'],
    };
    
    for (final entry in scheduleCompatibility.entries) {
      if (user.contains(entry.key) && 
          entry.value.any((schedule) => other.contains(schedule))) {
        return user.contains(entry.key) && other.contains(entry.key) ? 1.0 : 0.7;
      }
    }
    
    return 0.0;
  }

  /// Calculate session format match score
  double _calculateSessionFormatMatch(String userFormat, String otherFormat) {
    final user = userFormat.toLowerCase();
    final other = otherFormat.toLowerCase();
    
    // Exact match
    if (user == other) return 1.0;
    
    // Hybrid is compatible with most formats
    if (user.contains('hybrid') || other.contains('hybrid')) {
      return 0.8;
    }
    
    // Online and semi-async are somewhat compatible
    if ((user.contains('online') && other.contains('semi-async')) ||
        (user.contains('semi-async') && other.contains('online'))) {
      return 0.6;
    }
    
    return 0.0;
  }
} 
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';

abstract class EmbeddingService {
  /// Generate vector embedding for text
  Future<List<double>> generateEmbedding(String text);
  
  /// Generate embeddings for multiple texts in batch
  Future<List<List<double>>> generateEmbeddings(List<String> texts);
  
  /// Check if embedding service is available
  Future<bool> isAvailable();
}

class OpenAIEmbeddingService implements EmbeddingService {
  static const String _embeddingModel = 'text-embedding-3-small';
  static const int _maxInputLength = 8000; // Conservative limit for text-embedding-3-small
  
  OpenAIEmbeddingService({String? apiKey}) {
    if (apiKey != null && apiKey.isNotEmpty) {
      OpenAI.apiKey = apiKey;
    }
  }

  @override
  Future<List<double>> generateEmbedding(String text) async {
    try {
      final cleanText = _preprocessText(text);
      
      if (cleanText.isEmpty) {
        throw Exception('Text cannot be empty after preprocessing');
      }

      debugPrint('🔮 Generating embedding for text: ${cleanText.substring(0, cleanText.length > 50 ? 50 : cleanText.length)}...');

      final embedding = await OpenAI.instance.embedding.create(
        model: _embeddingModel,
        input: [cleanText],
      );

      if (embedding.data.isEmpty) {
        throw Exception('No embedding data returned from OpenAI');
      }

      final result = embedding.data.first.embeddings;
      debugPrint('✅ Generated embedding with ${result.length} dimensions');
      
      return result;
    } catch (e) {
      debugPrint('❌ Failed to generate embedding: $e');
      throw Exception('Failed to generate embedding: $e');
    }
  }

  @override
  Future<List<List<double>>> generateEmbeddings(List<String> texts) async {
    try {
      if (texts.isEmpty) {
        return [];
      }

      final cleanTexts = texts.map(_preprocessText).where((t) => t.isNotEmpty).toList();
      
      if (cleanTexts.isEmpty) {
        throw Exception('No valid texts after preprocessing');
      }

      debugPrint('🔮 Generating embeddings for ${cleanTexts.length} texts');

      final embedding = await OpenAI.instance.embedding.create(
        model: _embeddingModel,
        input: cleanTexts,
      );

      if (embedding.data.length != cleanTexts.length) {
        throw Exception('Mismatch between input texts and returned embeddings');
      }

      final results = embedding.data.map((data) => data.embeddings).toList();
      debugPrint('✅ Generated ${results.length} embeddings');
      
      return results;
    } catch (e) {
      debugPrint('❌ Failed to generate embeddings: $e');
      throw Exception('Failed to generate embeddings: $e');
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      // Test with a simple embedding
      await generateEmbedding('test');
      return true;
    } catch (e) {
      debugPrint('🔍 Embedding service not available: $e');
      return false;
    }
  }

  /// Preprocess text for embedding generation
  String _preprocessText(String text) {
    // Remove excessive whitespace and normalize
    String cleaned = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // Truncate if too long (keep some buffer for token encoding overhead)
    if (cleaned.length > _maxInputLength) {
      cleaned = '${cleaned.substring(0, _maxInputLength - 3)}...';
      debugPrint('⚠️ Text truncated to ${cleaned.length} characters');
    }
    
    return cleaned;
  }
}

/// Mock embedding service for testing and fallback
class MockEmbeddingService implements EmbeddingService {
  static const int _embeddingDimension = 1536; // Same as OpenAI text-embedding-3-small

  @override
  Future<List<double>> generateEmbedding(String text) async {
    // Generate a simple hash-based mock embedding
    final hash = text.hashCode;
    final random = hash % 1000000;
    
    return List.generate(_embeddingDimension, (index) {
      final value = ((random + index) % 2000 - 1000) / 1000.0;
      return value;
    });
  }

  @override
  Future<List<List<double>>> generateEmbeddings(List<String> texts) async {
    final results = <List<double>>[];
    for (final text in texts) {
      results.add(await generateEmbedding(text));
    }
    return results;
  }

  @override
  Future<bool> isAvailable() async {
    return true; // Mock is always available
  }
} 
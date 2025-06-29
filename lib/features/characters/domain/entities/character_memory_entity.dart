import 'dart:math';
import 'package:equatable/equatable.dart';

class CharacterMemoryEntity extends Equatable {
  const CharacterMemoryEntity({
    required this.id,
    required this.characterId,
    required this.userId,
    required this.content,
    required this.embedding,
    this.metadata = const {},
    this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String characterId;
  final String userId;
  final String content; // The actual text content that was vectorized
  final List<double> embedding; // Vector embedding from the text
  final Map<String, dynamic> metadata; // Additional context (type, tags, etc.)
  final String? source; // Optional source identifier (session notes, journal, etc.)
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    characterId,
    userId,
    content,
    embedding,
    metadata,
    source,
    createdAt,
    updatedAt,
  ];

  CharacterMemoryEntity copyWith({
    String? id,
    String? characterId,
    String? userId,
    String? content,
    List<double>? embedding,
    Map<String, dynamic>? metadata,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CharacterMemoryEntity(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      embedding: embedding ?? this.embedding,
      metadata: metadata ?? this.metadata,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get a brief summary for display purposes
  String get summary {
    return content.length > 100 
        ? '${content.substring(0, 100)}...'
        : content;
  }

  /// Calculate cosine similarity with another embedding
  double cosineSimilarity(List<double> other) {
    if (embedding.length != other.length) {
      throw ArgumentError('Embeddings must have the same dimension');
    }

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < embedding.length; i++) {
      dotProduct += embedding[i] * other[i];
      normA += embedding[i] * embedding[i];
      normB += other[i] * other[i];
    }

    normA = sqrt(normA);
    normB = sqrt(normB);

    if (normA == 0.0 || normB == 0.0) {
      return 0.0;
    }

    return dotProduct / (normA * normB);
  }

  /// Get content type from metadata or infer from content
  String get contentType {
    return metadata['type'] as String? ?? _inferContentType();
  }

  String _inferContentType() {
    final lowerContent = content.toLowerCase();
    
    if (lowerContent.contains(RegExp(r'\b(session|game|played|dm|gm)\b'))) {
      return 'session';
    } else if (lowerContent.contains(RegExp(r'\b(npc|met|talked|spoke)\b'))) {
      return 'npc_interaction';
    } else if (lowerContent.contains(RegExp(r'\b(journal|diary|thought|feel)\b'))) {
      return 'journal';
    } else if (lowerContent.contains(RegExp(r'\b(background|history|past|born)\b'))) {
      return 'backstory';
    } else {
      return 'general';
    }
  }
} 
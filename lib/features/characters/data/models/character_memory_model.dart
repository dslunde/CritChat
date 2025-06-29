import 'dart:convert';
import 'package:critchat/features/characters/domain/entities/character_memory_entity.dart';

class CharacterMemoryModel extends CharacterMemoryEntity {
  const CharacterMemoryModel({
    required super.id,
    required super.characterId,
    required super.userId,
    required super.content,
    required super.embedding,
    super.metadata,
    super.source,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CharacterMemoryModel.fromWeaviateJson(Map<String, dynamic> json) {
    try {
      // Parse metadata from JSON string
      Map<String, dynamic> metadata = {};
      if (json['metadata'] != null && json['metadata'].toString().isNotEmpty) {
        try {
          metadata = jsonDecode(json['metadata']) as Map<String, dynamic>;
        } catch (e) {
          // If metadata parsing fails, keep it empty
          metadata = {};
        }
      }

      return CharacterMemoryModel(
        id: json['_additional']?['id'] as String? ?? '',
        characterId: json['characterId'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        content: json['content'] as String? ?? '',
        embedding: [], // Embeddings are not returned in search results by default
        metadata: metadata,
        source: json['source'] as String?,
        createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to parse character memory from Weaviate JSON: $e');
    }
  }

  factory CharacterMemoryModel.fromEntity(CharacterMemoryEntity entity) {
    return CharacterMemoryModel(
      id: entity.id,
      characterId: entity.characterId,
      userId: entity.userId,
      content: entity.content,
      embedding: entity.embedding,
      metadata: entity.metadata,
      source: entity.source,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toWeaviateJson() {
    return {
      'characterId': characterId,
      'userId': userId,
      'content': content,
      'contentType': contentType,
      'source': source ?? '',
      'metadata': jsonEncode(metadata),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  CharacterMemoryModel copyWith({
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
    return CharacterMemoryModel(
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

  static DateTime? _parseDateTime(dynamic value) {
    try {
      if (value == null) return null;
      if (value is String) return DateTime.tryParse(value);
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Create a model with similarity score from search results
  CharacterMemoryModel withSimilarity(double similarity) {
    return copyWith(
      metadata: {
        ...metadata,
        'similarity': similarity,
      },
    );
  }

  /// Get similarity score if available
  double? get similarity {
    final sim = metadata['similarity'];
    if (sim is num) return sim.toDouble();
    return null;
  }
} 
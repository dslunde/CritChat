import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:critchat/features/characters/domain/entities/character_entity.dart';

class CharacterModel extends CharacterEntity {
  const CharacterModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.description,
    required super.personality,
    required super.backstory,
    required super.speechPatterns,
    super.quotes,
    super.isIndexed,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CharacterModel.fromJson(Map<String, dynamic> json, String id) {
    try {
      return CharacterModel(
        id: id,
        userId: json['userId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        personality: json['personality'] as String? ?? '',
        backstory: json['backstory'] as String? ?? '',
        speechPatterns: json['speechPatterns'] as String? ?? '',
        quotes: _safeStringList(json['quotes']),
        isIndexed: json['isIndexed'] as bool? ?? false,
        createdAt: _safeDateTime(json['createdAt']) ?? DateTime.now(),
        updatedAt: _safeDateTime(json['updatedAt']) ?? DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to parse character data: $e');
    }
  }

  static List<String> _safeStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static DateTime? _safeDateTime(dynamic value) {
    try {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    } catch (e) {
      return null;
    }
  }

  factory CharacterModel.fromEntity(CharacterEntity entity) {
    return CharacterModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      description: entity.description,
      personality: entity.personality,
      backstory: entity.backstory,
      speechPatterns: entity.speechPatterns,
      quotes: entity.quotes,
      isIndexed: entity.isIndexed,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'personality': personality,
      'backstory': backstory,
      'speechPatterns': speechPatterns,
      'quotes': quotes,
      'isIndexed': isIndexed,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  CharacterModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? personality,
    String? backstory,
    String? speechPatterns,
    List<String>? quotes,
    bool? isIndexed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CharacterModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      personality: personality ?? this.personality,
      backstory: backstory ?? this.backstory,
      speechPatterns: speechPatterns ?? this.speechPatterns,
      quotes: quotes ?? this.quotes,
      isIndexed: isIndexed ?? this.isIndexed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 
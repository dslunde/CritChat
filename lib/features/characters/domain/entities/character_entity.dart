import 'package:equatable/equatable.dart';

class CharacterEntity extends Equatable {
  const CharacterEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.personality,
    required this.backstory,
    required this.speechPatterns,
    this.quotes = const [],
    this.isIndexed = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String description;
  final String personality;
  final String backstory;
  final String speechPatterns;
  final List<String> quotes;
  final bool isIndexed; // Whether character is indexed in Weaviate
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    description,
    personality,
    backstory,
    speechPatterns,
    quotes,
    isIndexed,
    createdAt,
    updatedAt,
  ];

  CharacterEntity copyWith({
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
    return CharacterEntity(
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

  /// Get all character content for RAG indexing
  List<String> getIndexableContent() {
    return [
      'Name: $name',
      'Description: $description',
      'Personality: $personality',
      'Backstory: $backstory',
      'Speech Patterns: $speechPatterns',
      ...quotes.map((quote) => 'Quote: "$quote"'),
    ];
  }

  /// Get a brief summary for display
  String get summary {
    final desc = description.length > 100 
        ? '${description.substring(0, 100)}...'
        : description;
    return desc;
  }
} 
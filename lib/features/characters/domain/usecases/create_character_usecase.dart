import 'package:critchat/features/characters/domain/entities/character_entity.dart';
import 'package:critchat/features/characters/domain/repositories/character_repository.dart';

class CreateCharacterUseCase {
  final CharacterRepository repository;

  CreateCharacterUseCase({required this.repository});

  Future<CharacterEntity> call({
    required String userId,
    required String name,
    required String description,
    required String personality,
    required String backstory,
    required String speechPatterns,
    List<String> quotes = const [],
  }) async {
    // Validation
    if (name.trim().isEmpty) {
      throw Exception('Character name cannot be empty');
    }

    if (name.trim().length > 30) {
      throw Exception('Character name cannot exceed 30 characters');
    }

    if (description.trim().isEmpty) {
      throw Exception('Character description cannot be empty');
    }

    if (description.trim().length > 500) {
      throw Exception('Character description cannot exceed 500 characters');
    }

    if (personality.trim().isEmpty) {
      throw Exception('Character personality cannot be empty');
    }

    if (personality.trim().length > 1000) {
      throw Exception('Character personality cannot exceed 1000 characters');
    }

    if (backstory.trim().length > 2000) {
      throw Exception('Character backstory cannot exceed 2000 characters');
    }

    if (speechPatterns.trim().length > 1000) {
      throw Exception('Speech patterns cannot exceed 1000 characters');
    }

    // Check if user already has a character (one per user limit)
    final hasCharacter = await repository.userHasCharacter(userId);
    if (hasCharacter) {
      throw Exception('You can only have one character. Delete your existing character first.');
    }

    // Check for character name uniqueness for this user
    final existingCharacter = await repository.getCharacterByNameAndUser(
      name.trim(),
      userId,
    );
    if (existingCharacter != null) {
      throw Exception('You already have a character with this name');
    }

    // Validate quotes
    for (final quote in quotes) {
      if (quote.trim().length > 200) {
        throw Exception('Character quotes cannot exceed 200 characters each');
      }
    }

    if (quotes.length > 10) {
      throw Exception('Character cannot have more than 10 quotes');
    }

    final now = DateTime.now();
    final character = CharacterEntity(
      id: '', // Will be set by repository
      userId: userId,
      name: name.trim(),
      description: description.trim(),
      personality: personality.trim(),
      backstory: backstory.trim(),
      speechPatterns: speechPatterns.trim(),
      quotes: quotes.map((q) => q.trim()).where((q) => q.isNotEmpty).toList(),
      isIndexed: false,
      createdAt: now,
      updatedAt: now,
    );

    return await repository.createCharacter(character);
  }
} 
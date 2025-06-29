import 'package:critchat/features/characters/domain/entities/character_memory_entity.dart';
import 'package:critchat/features/characters/domain/repositories/character_memory_repository.dart';
import 'package:critchat/core/embeddings/embedding_service.dart';

class StoreCharacterMemoryUseCase {
  final CharacterMemoryRepository repository;
  final EmbeddingService embeddingService;

  StoreCharacterMemoryUseCase({
    required this.repository,
    required this.embeddingService,
  });

  Future<CharacterMemoryEntity> call({
    required String characterId,
    required String userId,
    required String content,
    Map<String, dynamic>? metadata,
    String? source,
  }) async {
    // Validation
    if (characterId.trim().isEmpty) {
      throw Exception('Character ID cannot be empty');
    }

    if (userId.trim().isEmpty) {
      throw Exception('User ID cannot be empty');
    }

    if (content.trim().isEmpty) {
      throw Exception('Memory content cannot be empty');
    }

    if (content.trim().length < 10) {
      throw Exception('Memory content must be at least 10 characters');
    }

    if (content.trim().length > 5000) {
      throw Exception('Memory content cannot exceed 5000 characters');
    }

    // Generate embedding for the content
    final embedding = await embeddingService.generateEmbedding(content.trim());

    final now = DateTime.now();
    final memory = CharacterMemoryEntity(
      id: '', // Will be set by repository
      characterId: characterId,
      userId: userId,
      content: content.trim(),
      embedding: embedding,
      metadata: metadata ?? {},
      source: source?.trim(),
      createdAt: now,
      updatedAt: now,
    );

    return await repository.storeMemory(memory);
  }
} 
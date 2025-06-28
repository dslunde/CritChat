import 'package:flutter/foundation.dart';
import 'package:critchat/features/characters/domain/entities/character_entity.dart';
import 'package:critchat/core/chat/chat_realtime_datasource.dart';

abstract class RagService {
  /// Generate a character response based on the character's personality and context
  Future<String> generateCharacterResponse({
    required CharacterEntity character,
    required String userPrompt,
    required List<Message> recentContext,
  });

  /// Index a character's information in the vector database
  Future<void> indexCharacter(CharacterEntity character);

  /// Update character index when character is modified
  Future<void> updateCharacterIndex(CharacterEntity character);

  /// Remove character from index when deleted
  Future<void> removeCharacterIndex(String characterId);
}

class RagServiceImpl implements RagService {
  // TODO: Add Weaviate client when ready
  // final WeaviateClient _weaviateClient;
  // final EmbeddingService _embeddingService;

  RagServiceImpl();

  @override
  Future<String> generateCharacterResponse({
    required CharacterEntity character,
    required String userPrompt,
    required List<Message> recentContext,
  }) async {
    try {
      // For now, create a simple character-based response
      // TODO: Replace with actual RAG implementation using Weaviate + LLM
      return await _generateSimpleCharacterResponse(character, userPrompt, recentContext);
    } catch (e) {
      throw Exception('Failed to generate character response: $e');
    }
  }

  @override
  Future<void> indexCharacter(CharacterEntity character) async {
    try {
      // TODO: Implement Weaviate indexing
      // For now, just log that indexing would happen
      debugPrint('📚 Would index character: ${character.name}');
      debugPrint('📚 Indexable content chunks: ${character.getIndexableContent().length}');
    } catch (e) {
      throw Exception('Failed to index character: $e');
    }
  }

  @override
  Future<void> updateCharacterIndex(CharacterEntity character) async {
    try {
      // TODO: Implement Weaviate index update
      debugPrint('🔄 Would update character index: ${character.name}');
    } catch (e) {
      throw Exception('Failed to update character index: $e');
    }
  }

  @override
  Future<void> removeCharacterIndex(String characterId) async {
    try {
      // TODO: Implement Weaviate index removal
      debugPrint('🗑️ Would remove character index: $characterId');
    } catch (e) {
      throw Exception('Failed to remove character index: $e');
    }
  }

  /// Simple character response generation (placeholder until full RAG is implemented)
  Future<String> _generateSimpleCharacterResponse(
    CharacterEntity character,
    String userPrompt,
    List<Message> recentContext,
  ) async {
    // Create a character-appropriate response based on personality and speech patterns
    final response = _craftCharacterResponse(character, userPrompt);
    
    // Add some delay to simulate LLM processing
    await Future.delayed(const Duration(milliseconds: 500));
    
    return response;
  }

  String _craftCharacterResponse(CharacterEntity character, String userPrompt) {
    // Analyze the character's personality and speech patterns
    final personality = character.personality.toLowerCase();
    final speechPatterns = character.speechPatterns.toLowerCase();
    final isPromptQuestion = userPrompt.trim().endsWith('?');
    
    // Build response based on character traits
    String response = '';
    
    // Add character-appropriate greeting or acknowledgment
    if (personality.contains('confident') || personality.contains('bold')) {
      response = isPromptQuestion ? 'Absolutely! ' : 'Listen well - ';
    } else if (personality.contains('mysterious') || personality.contains('secretive')) {
      response = isPromptQuestion ? 'Perhaps... ' : 'In shadows I speak: ';
    } else if (personality.contains('wise') || personality.contains('learned')) {
      response = isPromptQuestion ? 'Indeed, ' : 'As I have observed, ';
    } else if (personality.contains('cheerful') || personality.contains('optimistic')) {
      response = isPromptQuestion ? 'Oh yes! ' : 'With joy I say: ';
    } else {
      response = isPromptQuestion ? 'Well, ' : '';
    }
    
    // Add the core message, modified by speech patterns
    String coreMessage = userPrompt;
    
    // Modify based on speech patterns
    if (speechPatterns.contains('formal') || speechPatterns.contains('eloquent')) {
      coreMessage = _makeMoreFormal(coreMessage);
    } else if (speechPatterns.contains('casual') || speechPatterns.contains('slang')) {
      coreMessage = _makeCasual(coreMessage);
    } else if (speechPatterns.contains('archaic') || speechPatterns.contains('old')) {
      coreMessage = _makeArchaic(coreMessage);
    }
    
    response += coreMessage;
    
    // Add character-appropriate ending
    if (speechPatterns.contains('dramatic')) {
      response += '!';
    } else if (personality.contains('mysterious')) {
      response += '...';
    } else if (personality.contains('wise')) {
      response += ', as experience has taught me.';
    }
    
    return response;
  }

  String _makeMoreFormal(String text) {
    return text
        .replaceAll(RegExp(r"\bcan't\b"), 'cannot')
        .replaceAll(RegExp(r"\bwon't\b"), 'will not')
        .replaceAll(RegExp(r"\bdon't\b"), 'do not')
        .replaceAll(RegExp(r"\bisn't\b"), 'is not');
  }

  String _makeCasual(String text) {
    return text
        .replaceAll(RegExp(r'\bcannot\b'), "can't")
        .replaceAll(RegExp(r'\bwill not\b'), "won't")
        .replaceAll(RegExp(r'\bdo not\b'), "don't");
  }

  String _makeArchaic(String text) {
    return text
        .replaceAll(RegExp(r'\byou\b'), 'thee')
        .replaceAll(RegExp(r'\byour\b'), 'thy')
        .replaceAll(RegExp(r'\bare\b'), 'art');
  }
} 
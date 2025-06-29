import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';
import 'package:critchat/features/characters/domain/entities/character_entity.dart';
import 'package:critchat/features/characters/domain/entities/character_memory_entity.dart';
import 'package:critchat/core/chat/chat_realtime_datasource.dart';

abstract class LlmService {
  /// Generate a character response using retrieved context
  Future<String> generateCharacterResponse({
    required CharacterEntity character,
    required String userPrompt,
    required List<CharacterMemoryEntity> relevantMemories,
    required List<Message> recentContext,
  });

  /// Check if LLM service is available
  Future<bool> isAvailable();
}

class OpenAILlmService implements LlmService {
  static const String _chatModel = 'gpt-4o-mini';
  static const int _maxTokens = 500;
  static const double _temperature = 0.8;

  OpenAILlmService({String? apiKey}) {
    if (apiKey != null && apiKey.isNotEmpty) {
      OpenAI.apiKey = apiKey;
    }
  }

  @override
  Future<String> generateCharacterResponse({
    required CharacterEntity character,
    required String userPrompt,
    required List<CharacterMemoryEntity> relevantMemories,
    required List<Message> recentContext,
  }) async {
    try {
      debugPrint('🤖 Generating character response for: ${character.name}');
      
      final systemPrompt = _buildSystemPrompt(character, relevantMemories);
      final userMessage = _buildUserMessage(userPrompt, recentContext);

      debugPrint('📝 System prompt length: ${systemPrompt.length} chars');
      debugPrint('📝 User message length: ${userMessage.length} chars');
      debugPrint('📊 Using ${relevantMemories.length} relevant memories');

      final chatCompletion = await OpenAI.instance.chat.create(
        model: _chatModel,
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(systemPrompt),
            ],
          ),
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(userMessage),
            ],
          ),
        ],
        temperature: _temperature,
        maxTokens: _maxTokens,
      );

      if (chatCompletion.choices.isEmpty) {
        throw Exception('No response generated from LLM');
      }

      final response = chatCompletion.choices.first.message.content?.first.text ?? '';
      
      if (response.isEmpty) {
        throw Exception('Empty response from LLM');
      }

      debugPrint('✅ Generated character response: ${response.substring(0, response.length > 50 ? 50 : response.length)}...');
      return response;
    } catch (e) {
      debugPrint('❌ Failed to generate character response: $e');
      throw Exception('Failed to generate character response: $e');
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      // Test with a simple completion
      final testCompletion = await OpenAI.instance.chat.create(
        model: _chatModel,
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text('Say "test"'),
            ],
          ),
        ],
        maxTokens: 5,
      );
      
      return testCompletion.choices.isNotEmpty;
    } catch (e) {
      debugPrint('🔍 LLM service not available: $e');
      return false;
    }
  }

  String _buildSystemPrompt(CharacterEntity character, List<CharacterMemoryEntity> memories) {
    final buffer = StringBuffer();
    
    // Character basic information
    buffer.writeln('You are roleplaying as ${character.name}, a character in a tabletop RPG setting.');
    buffer.writeln();
    
    // Core character information
    buffer.writeln('CHARACTER PROFILE:');
    buffer.writeln('Name: ${character.name}');
    buffer.writeln('Description: ${character.description}');
    buffer.writeln('Personality: ${character.personality}');
    if (character.backstory.isNotEmpty) {
      buffer.writeln('Backstory: ${character.backstory}');
    }
    if (character.speechPatterns.isNotEmpty) {
      buffer.writeln('Speech Patterns: ${character.speechPatterns}');
    }
    if (character.quotes.isNotEmpty) {
      buffer.writeln('Example Quotes: ${character.quotes.join(', ')}');
    }
    buffer.writeln();

    // Relevant memories and experiences
    if (memories.isNotEmpty) {
      buffer.writeln('RELEVANT MEMORIES AND EXPERIENCES:');
      for (final memory in memories) {
        buffer.writeln('- ${memory.content}');
      }
      buffer.writeln();
    }

    // Instructions
    buffer.writeln('INSTRUCTIONS:');
    buffer.writeln('- Respond as ${character.name} would, staying true to their personality and background');
    buffer.writeln('- Use the relevant memories to inform your response when appropriate');
    buffer.writeln('- Maintain consistency with ${character.name}\'s established speech patterns and personality');
    buffer.writeln('- Keep responses conversational and natural for a group chat setting');
    buffer.writeln('- Do not break character or reference that you are an AI');
    buffer.writeln('- Keep responses to 1-3 sentences unless more detail is specifically needed');
    
    return buffer.toString();
  }

  String _buildUserMessage(String userPrompt, List<Message> recentContext) {
    final buffer = StringBuffer();
    
    // Recent conversation context
    if (recentContext.isNotEmpty) {
      buffer.writeln('RECENT CONVERSATION:');
      for (final message in recentContext) {
        final sender = message.isCharacterMessage 
            ? '${message.senderName} as ${message.characterName}'
            : message.senderName;
        buffer.writeln('$sender: ${message.content}');
      }
      buffer.writeln();
    }

    // The actual prompt/message to respond to
    buffer.writeln('Now respond to this message as your character:');
    buffer.writeln('"$userPrompt"');
    
    return buffer.toString();
  }
}

/// Mock LLM service for testing and fallback
class MockLlmService implements LlmService {
  @override
  Future<String> generateCharacterResponse({
    required CharacterEntity character,
    required String userPrompt,
    required List<CharacterMemoryEntity> relevantMemories,
    required List<Message> recentContext,
  }) async {
    // Simple rule-based response generation as fallback
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate API delay
    
    final personality = character.personality.toLowerCase();
    String prefix = '';
    
    if (personality.contains('confident') || personality.contains('bold')) {
      prefix = 'Absolutely! ';
    } else if (personality.contains('mysterious') || personality.contains('secretive')) {
      prefix = 'Perhaps... ';
    } else if (personality.contains('wise') || personality.contains('learned')) {
      prefix = 'Indeed, ';
    } else if (personality.contains('cheerful') || personality.contains('optimistic')) {
      prefix = 'Oh yes! ';
    }
    
    // Use memory context if available
    String contextualResponse = userPrompt;
    if (relevantMemories.isNotEmpty) {
      final memory = relevantMemories.first;
      if (memory.contentType == 'npc_interaction') {
        contextualResponse = 'Reminds me of someone I once met... $userPrompt';
      } else if (memory.contentType == 'session') {
        contextualResponse = 'From my experience, $userPrompt';
      }
    }
    
    return '$prefix$contextualResponse';
  }

  @override
  Future<bool> isAvailable() async {
    return true; // Mock is always available
  }
} 
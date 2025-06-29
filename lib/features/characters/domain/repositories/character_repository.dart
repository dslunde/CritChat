import 'package:critchat/features/characters/domain/entities/character_entity.dart';

abstract class CharacterRepository {
  /// Get user's character (limit one per user for now)
  Future<CharacterEntity?> getUserCharacter(String userId);
  
  /// Create a new character for user
  Future<CharacterEntity> createCharacter(CharacterEntity character);
  
  /// Update an existing character
  Future<CharacterEntity> updateCharacter(CharacterEntity character);
  
  /// Delete user's character
  Future<void> deleteCharacter(String characterId);
  
  /// Get character by ID
  Future<CharacterEntity?> getCharacterById(String characterId);
  
  /// Get character by name and user ID (for @as command validation)
  Future<CharacterEntity?> getCharacterByNameAndUser(String name, String userId);
  
  /// Check if user has a character
  Future<bool> userHasCharacter(String userId);
} 
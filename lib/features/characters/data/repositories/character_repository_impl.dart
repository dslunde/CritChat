import 'package:critchat/features/characters/domain/entities/character_entity.dart';
import 'package:critchat/features/characters/domain/repositories/character_repository.dart';
import 'package:critchat/features/characters/data/datasources/character_firestore_datasource.dart';
import 'package:critchat/features/characters/data/models/character_model.dart';

class CharacterRepositoryImpl implements CharacterRepository {
  final CharacterFirestoreDataSource dataSource;

  CharacterRepositoryImpl({required this.dataSource});

  @override
  Future<CharacterEntity?> getUserCharacter(String userId) async {
    try {
      return await dataSource.getUserCharacter(userId);
    } catch (e) {
      throw Exception('Failed to get user character: ${e.toString()}');
    }
  }

  @override
  Future<CharacterEntity> createCharacter(CharacterEntity character) async {
    try {
      final characterModel = CharacterModel.fromEntity(character);
      return await dataSource.createCharacter(characterModel);
    } catch (e) {
      throw Exception('Failed to create character: ${e.toString()}');
    }
  }

  @override
  Future<CharacterEntity> updateCharacter(CharacterEntity character) async {
    try {
      final characterModel = CharacterModel.fromEntity(character);
      return await dataSource.updateCharacter(characterModel);
    } catch (e) {
      throw Exception('Failed to update character: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteCharacter(String characterId) async {
    try {
      await dataSource.deleteCharacter(characterId);
    } catch (e) {
      throw Exception('Failed to delete character: ${e.toString()}');
    }
  }

  @override
  Future<CharacterEntity?> getCharacterById(String characterId) async {
    try {
      return await dataSource.getCharacterById(characterId);
    } catch (e) {
      throw Exception('Failed to get character by ID: ${e.toString()}');
    }
  }

  @override
  Future<CharacterEntity?> getCharacterByNameAndUser(String name, String userId) async {
    try {
      return await dataSource.getCharacterByNameAndUser(name, userId);
    } catch (e) {
      throw Exception('Failed to get character by name and user: ${e.toString()}');
    }
  }

  @override
  Future<bool> userHasCharacter(String userId) async {
    try {
      return await dataSource.userHasCharacter(userId);
    } catch (e) {
      throw Exception('Failed to check if user has character: ${e.toString()}');
    }
  }
} 
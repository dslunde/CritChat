import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:critchat/features/characters/data/models/character_model.dart';

abstract class CharacterFirestoreDataSource {
  Future<CharacterModel?> getUserCharacter(String userId);
  Future<CharacterModel> createCharacter(CharacterModel character);
  Future<CharacterModel> updateCharacter(CharacterModel character);
  Future<void> deleteCharacter(String characterId);
  Future<CharacterModel?> getCharacterById(String characterId);
  Future<CharacterModel?> getCharacterByNameAndUser(String name, String userId);
  Future<bool> userHasCharacter(String userId);
}

class CharacterFirestoreDataSourceImpl implements CharacterFirestoreDataSource {
  final FirebaseFirestore _firestore;

  CharacterFirestoreDataSourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<CharacterModel?> getUserCharacter(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('characters')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      return CharacterModel.fromJson(doc.data(), doc.id);
    } catch (e) {
      debugPrint('Failed to get user character: $e');
      throw Exception('Failed to get user character: $e');
    }
  }

  @override
  Future<CharacterModel> createCharacter(CharacterModel character) async {
    try {
      final docRef = await _firestore
          .collection('characters')
          .add(character.toJson());

      final newCharacter = character.copyWith(id: docRef.id);

      // Update the document with the generated ID
      await docRef.update({'id': docRef.id});

      debugPrint('✅ Created character: ${newCharacter.name}');
      return newCharacter;
    } catch (e) {
      debugPrint('Failed to create character: $e');
      throw Exception('Failed to create character: $e');
    }
  }

  @override
  Future<CharacterModel> updateCharacter(CharacterModel character) async {
    try {
      await _firestore
          .collection('characters')
          .doc(character.id)
          .update(character.toJson());

      debugPrint('✅ Updated character: ${character.name}');
      return character;
    } catch (e) {
      debugPrint('Failed to update character: $e');
      throw Exception('Failed to update character: $e');
    }
  }

  @override
  Future<void> deleteCharacter(String characterId) async {
    try {
      await _firestore
          .collection('characters')
          .doc(characterId)
          .delete();

      debugPrint('✅ Deleted character: $characterId');
    } catch (e) {
      debugPrint('Failed to delete character: $e');
      throw Exception('Failed to delete character: $e');
    }
  }

  @override
  Future<CharacterModel?> getCharacterById(String characterId) async {
    try {
      final doc = await _firestore
          .collection('characters')
          .doc(characterId)
          .get();

      if (!doc.exists || doc.data() == null) return null;

      return CharacterModel.fromJson(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Failed to get character by ID: $e');
      throw Exception('Failed to get character by ID: $e');
    }
  }

  @override
  Future<CharacterModel?> getCharacterByNameAndUser(String name, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('characters')
          .where('userId', isEqualTo: userId)
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      return CharacterModel.fromJson(doc.data(), doc.id);
    } catch (e) {
      debugPrint('Failed to get character by name and user: $e');
      throw Exception('Failed to get character by name and user: $e');
    }
  }

  @override
  Future<bool> userHasCharacter(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('characters')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Failed to check if user has character: $e');
      throw Exception('Failed to check if user has character: $e');
    }
  }
} 
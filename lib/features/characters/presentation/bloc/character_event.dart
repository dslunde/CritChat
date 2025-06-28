import 'package:equatable/equatable.dart';

abstract class CharacterEvent extends Equatable {
  const CharacterEvent();

  @override
  List<Object?> get props => [];
}

class GetUserCharacter extends CharacterEvent {
  final String userId;

  const GetUserCharacter({required this.userId});

  @override
  List<Object> get props => [userId];
}

class CreateCharacter extends CharacterEvent {
  final String userId;
  final String name;
  final String description;
  final String personality;
  final String backstory;
  final String speechPatterns;
  final List<String> quotes;

  const CreateCharacter({
    required this.userId,
    required this.name,
    required this.description,
    required this.personality,
    required this.backstory,
    required this.speechPatterns,
    this.quotes = const [],
  });

  @override
  List<Object> get props => [
    userId,
    name,
    description,
    personality,
    backstory,
    speechPatterns,
    quotes,
  ];
}

class UpdateCharacter extends CharacterEvent {
  final String characterId;
  final String userId;
  final String? name;
  final String? description;
  final String? personality;
  final String? backstory;
  final String? speechPatterns;
  final List<String>? quotes;

  const UpdateCharacter({
    required this.characterId,
    required this.userId,
    this.name,
    this.description,
    this.personality,
    this.backstory,
    this.speechPatterns,
    this.quotes,
  });

  @override
  List<Object?> get props => [
    characterId,
    userId,
    name,
    description,
    personality,
    backstory,
    speechPatterns,
    quotes,
  ];
} 
import 'package:equatable/equatable.dart';
import 'package:critchat/features/characters/domain/entities/character_entity.dart';

abstract class CharacterState extends Equatable {
  const CharacterState();

  @override
  List<Object?> get props => [];
}

class CharacterInitial extends CharacterState {}

class CharacterLoading extends CharacterState {}

class CharacterEmpty extends CharacterState {}

class CharacterLoaded extends CharacterState {
  final CharacterEntity character;

  const CharacterLoaded(this.character);

  @override
  List<Object> get props => [character];
}

class CharacterCreated extends CharacterState {
  final CharacterEntity character;

  const CharacterCreated(this.character);

  @override
  List<Object> get props => [character];
}

class CharacterUpdated extends CharacterState {
  final CharacterEntity character;

  const CharacterUpdated(this.character);

  @override
  List<Object> get props => [character];
}

class CharacterError extends CharacterState {
  final String message;

  const CharacterError(this.message);

  @override
  List<Object> get props => [message];
} 
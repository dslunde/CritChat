import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:critchat/features/characters/domain/usecases/create_character_usecase.dart';
import 'package:critchat/features/characters/domain/usecases/get_user_character_usecase.dart';
import 'package:critchat/features/characters/domain/usecases/update_character_usecase.dart';
import 'package:critchat/core/rag/rag_service.dart';
import 'character_event.dart';
import 'character_state.dart';

class CharacterBloc extends Bloc<CharacterEvent, CharacterState> {
  final CreateCharacterUseCase createCharacterUseCase;
  final GetUserCharacterUseCase getUserCharacterUseCase;
  final UpdateCharacterUseCase updateCharacterUseCase;
  final RagService ragService;

  CharacterBloc({
    required this.createCharacterUseCase,
    required this.getUserCharacterUseCase,
    required this.updateCharacterUseCase,
    required this.ragService,
  }) : super(CharacterInitial()) {
    on<GetUserCharacter>(_onGetUserCharacter);
    on<CreateCharacter>(_onCreateCharacter);
    on<UpdateCharacter>(_onUpdateCharacter);
  }

  Future<void> _onGetUserCharacter(
    GetUserCharacter event,
    Emitter<CharacterState> emit,
  ) async {
    try {
      emit(CharacterLoading());
      final character = await getUserCharacterUseCase(event.userId);
      if (character != null) {
        emit(CharacterLoaded(character));
      } else {
        emit(CharacterEmpty());
      }
    } catch (e) {
      emit(CharacterError(e.toString()));
    }
  }

  Future<void> _onCreateCharacter(
    CreateCharacter event,
    Emitter<CharacterState> emit,
  ) async {
    try {
      emit(CharacterLoading());
      final character = await createCharacterUseCase(
        userId: event.userId,
        name: event.name,
        description: event.description,
        personality: event.personality,
        backstory: event.backstory,
        speechPatterns: event.speechPatterns,
        quotes: event.quotes,
      );

      // Index the character in RAG service
      try {
        await ragService.indexCharacter(character);
      } catch (e) {
        // Don't fail character creation if indexing fails
        debugPrint('⚠️ Failed to index character: $e');
      }

      emit(CharacterCreated(character));
    } catch (e) {
      emit(CharacterError(e.toString()));
    }
  }

  Future<void> _onUpdateCharacter(
    UpdateCharacter event,
    Emitter<CharacterState> emit,
  ) async {
    try {
      emit(CharacterLoading());
      final character = await updateCharacterUseCase(
        characterId: event.characterId,
        userId: event.userId,
        name: event.name,
        description: event.description,
        personality: event.personality,
        backstory: event.backstory,
        speechPatterns: event.speechPatterns,
        quotes: event.quotes,
      );

      // Update the character index in RAG service
      try {
        await ragService.updateCharacterIndex(character);
      } catch (e) {
        // Don't fail character update if indexing fails
        debugPrint('⚠️ Failed to update character index: $e');
      }

      emit(CharacterUpdated(character));
    } catch (e) {
      emit(CharacterError(e.toString()));
    }
  }
} 
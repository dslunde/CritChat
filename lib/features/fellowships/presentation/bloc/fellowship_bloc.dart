import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../../domain/usecases/get_fellowships_usecase.dart';
import '../../domain/usecases/create_fellowship_usecase.dart';
import '../../domain/usecases/invite_friend_usecase.dart';
import 'fellowship_event.dart';
import 'fellowship_state.dart';

class FellowshipBloc extends Bloc<FellowshipEvent, FellowshipState> {
  final GetFellowshipsUseCase getFellowshipsUseCase;
  final CreateFellowshipUseCase createFellowshipUseCase;
  final InviteFriendUseCase inviteFriendUseCase;

  FellowshipBloc({
    required this.getFellowshipsUseCase,
    required this.createFellowshipUseCase,
    required this.inviteFriendUseCase,
  }) : super(FellowshipInitial()) {
    on<GetFellowships>(_onGetFellowships);
    on<CreateFellowship>(_onCreateFellowship);
    on<InviteFriend>(_onInviteFriend);
    on<RemoveMember>(_onRemoveMember);
    on<DeleteFellowship>(_onDeleteFellowship);
    on<GetPublicFellowships>(_onGetPublicFellowships);
    on<GetUserFellowships>(_onGetUserFellowships);
  }

  Future<void> _onGetFellowships(
    GetFellowships event,
    Emitter<FellowshipState> emit,
  ) async {
    try {
      emit(FellowshipLoading());
      final fellowships = await getFellowshipsUseCase();
      emit(FellowshipLoaded(fellowships));
    } catch (e) {
      debugPrint('Error getting fellowships: $e');
      emit(FellowshipError('Failed to get fellowships'));
    }
  }

  Future<void> _onCreateFellowship(
    CreateFellowship event,
    Emitter<FellowshipState> emit,
  ) async {
    try {
      emit(FellowshipLoading());

      final fellowship = await createFellowshipUseCase(
        name: event.name,
        description: event.description,
        gameSystem: event.gameSystem,
        isPublic: event.isPublic,
        creatorId: event.creatorId,
      );

      emit(FellowshipCreated(fellowship));
    } catch (e) {
      debugPrint('Error creating fellowship: $e');
      emit(FellowshipError('Failed to create fellowship: ${e.toString()}'));
    }
  }

  Future<void> _onInviteFriend(
    InviteFriend event,
    Emitter<FellowshipState> emit,
  ) async {
    try {
      emit(FellowshipLoading());
      final success = await inviteFriendUseCase(
        event.fellowshipId,
        event.friendId,
      );

      if (success) {
        emit(FriendInvited());
        // Reload fellowships to show updated member count
        add(GetFellowships());
      } else {
        emit(const FellowshipError('Failed to invite friend'));
      }
    } catch (e) {
      debugPrint('Error inviting friend: $e');
      emit(FellowshipError('Failed to invite friend'));
    }
  }

  Future<void> _onRemoveMember(
    RemoveMember event,
    Emitter<FellowshipState> emit,
  ) async {
    try {
      emit(FellowshipLoading());
      // This would be implemented when we have the remove member use case
      emit(MemberRemoved());
      add(GetFellowships());
    } catch (e) {
      debugPrint('Error removing member: $e');
      emit(FellowshipError('Failed to remove member'));
    }
  }

  Future<void> _onDeleteFellowship(
    DeleteFellowship event,
    Emitter<FellowshipState> emit,
  ) async {
    try {
      emit(FellowshipLoading());
      // This would be implemented when we have the delete fellowship use case
      emit(FellowshipDeleted());
      add(GetFellowships());
    } catch (e) {
      debugPrint('Error deleting fellowship: $e');
      emit(FellowshipError('Failed to delete fellowship'));
    }
  }

  Future<void> _onGetPublicFellowships(
    GetPublicFellowships event,
    Emitter<FellowshipState> emit,
  ) async {
    try {
      emit(FellowshipLoading());
      final fellowships = await getFellowshipsUseCase();
      final publicFellowships = fellowships.where((f) => f.isPublic).toList();
      emit(FellowshipLoaded(publicFellowships));
    } catch (e) {
      debugPrint('Error getting public fellowships: $e');
      emit(FellowshipError('Failed to get public fellowships'));
    }
  }

  Future<void> _onGetUserFellowships(
    GetUserFellowships event,
    Emitter<FellowshipState> emit,
  ) async {
    try {
      emit(FellowshipLoading());
      final fellowships = await getFellowshipsUseCase();
      final userFellowships = fellowships
          .where((f) => f.memberIds.contains(event.userId))
          .toList();
      emit(FellowshipLoaded(userFellowships));
    } catch (e) {
      debugPrint('Error getting user fellowships: $e');
      emit(FellowshipError('Failed to get user fellowships'));
    }
  }
}

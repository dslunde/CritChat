import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import 'package:critchat/features/fellowships/domain/usecases/get_fellowships_usecase.dart';
import 'package:critchat/features/fellowships/domain/usecases/create_fellowship_usecase.dart';
import 'package:critchat/features/fellowships/domain/usecases/invite_friend_usecase.dart';
import 'package:critchat/features/fellowships/domain/usecases/get_public_fellowships_usecase.dart';
import 'package:critchat/features/fellowships/domain/usecases/join_fellowship_by_code_usecase.dart';
import 'package:critchat/features/fellowships/domain/usecases/remove_member_usecase.dart';
import 'package:critchat/features/fellowships/domain/entities/fellowship_entity.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_event.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_state.dart';
import 'package:critchat/core/di/injection_container.dart';
import 'package:critchat/core/gamification/gamification_service.dart';

class FellowshipBloc extends Bloc<FellowshipEvent, FellowshipState> {
  final GetFellowshipsUseCase getFellowshipsUseCase;
  final CreateFellowshipUseCase createFellowshipUseCase;
  final InviteFriendUseCase inviteFriendUseCase;
  final GetPublicFellowshipsUseCase getPublicFellowshipsUseCase;
  final JoinFellowshipByCodeUseCase joinFellowshipByCodeUseCase;
  final RemoveMemberUseCase removeMemberUseCase;

  FellowshipBloc({
    required this.getFellowshipsUseCase,
    required this.createFellowshipUseCase,
    required this.inviteFriendUseCase,
    required this.getPublicFellowshipsUseCase,
    required this.joinFellowshipByCodeUseCase,
    required this.removeMemberUseCase,
  }) : super(FellowshipInitial()) {
    on<GetFellowships>(_onGetFellowships);
    on<CreateFellowship>(_onCreateFellowship);
    on<InviteFriend>(_onInviteFriend);
    on<RemoveMember>(_onRemoveMember);
    on<DeleteFellowship>(_onDeleteFellowship);
    on<GetPublicFellowships>(_onGetPublicFellowships);
    on<GetUserFellowships>(_onGetUserFellowships);
    on<JoinFellowshipByCode>(_onJoinFellowshipByCode);
    on<JoinPublicFellowship>(_onJoinPublicFellowship);
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
        joinCode: event.joinCode,
      );

      // Award XP for creating fellowship
      try {
        final gamificationService = sl<GamificationService>();
        await gamificationService.awardFellowshipCreated(fellowship.id);
        debugPrint('✅ Awarded fellowship creation XP');
      } catch (e) {
        debugPrint('⚠️ Failed to award fellowship creation XP: $e');
      }

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
      final success = await removeMemberUseCase(
        event.fellowshipId,
        event.memberId,
      );

      if (success) {
        emit(MemberRemoved());
        // Reload fellowships to show updated member count
        add(GetFellowships());
      } else {
        emit(const FellowshipError('Failed to remove member'));
      }
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
      final fellowships = await getPublicFellowshipsUseCase();
      emit(PublicFellowshipsLoaded(fellowships));
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

  Future<void> _onJoinFellowshipByCode(
    JoinFellowshipByCode event,
    Emitter<FellowshipState> emit,
  ) async {
    try {
      emit(FellowshipLoading());
      final success = await joinFellowshipByCodeUseCase(
        name: event.name,
        joinCode: event.joinCode,
        userId: event.userId,
      );

      if (success) {
        // Award XP for joining fellowship
        try {
          final gamificationService = sl<GamificationService>();
          await gamificationService.awardFellowshipJoined('fellowship_by_code');
          debugPrint('✅ Awarded fellowship join XP');
        } catch (e) {
          debugPrint('⚠️ Failed to award fellowship join XP: $e');
        }

        emit(const FellowshipJoined('Successfully joined fellowship!'));
        // Reload fellowships to show the newly joined fellowship
        add(GetFellowships());
      } else {
        emit(
          const FellowshipError('Fellowship not found or join code incorrect'),
        );
      }
    } catch (e) {
      debugPrint('Error joining fellowship by code: $e');
      // Use the specific error message from the use case
      final errorMessage = e.toString().contains('Could not join fellowship')
          ? e.toString().replaceAll('Exception: ', '')
          : 'Could not join fellowship. Double check the name and join code match *exactly* what your GM gave you.';
      emit(FellowshipError(errorMessage));
    }
  }

  Future<void> _onJoinPublicFellowship(
    JoinPublicFellowship event,
    Emitter<FellowshipState> emit,
  ) async {
    try {
      emit(FellowshipLoading());

      // Get all public fellowships to find the specific one
      final publicFellowships = await getPublicFellowshipsUseCase();

      // Find the fellowship by ID safely
      FellowshipEntity? fellowship;
      try {
        fellowship = publicFellowships.firstWhere(
          (f) => f.id == event.fellowshipId,
        );
      } catch (e) {
        // Fellowship not found in public fellowships
        fellowship = null;
      }

      if (fellowship == null) {
        emit(const FellowshipError('Fellowship not found'));
        return;
      }

      // Check if user isn't already a member
      if (fellowship.memberIds.contains(event.userId)) {
        emit(
          const FellowshipError('You are already a member of this fellowship'),
        );
        return;
      }

      // For public fellowships, we can join directly without join code validation
      // Since we already confirmed it's public and user isn't a member
      final success = await _joinPublicFellowshipDirectly(
        fellowship.id,
        event.userId,
      );

      if (success) {
        // Award XP for joining fellowship
        try {
          final gamificationService = sl<GamificationService>();
          await gamificationService.awardFellowshipJoined(event.fellowshipId);
          debugPrint('✅ Awarded fellowship join XP');
        } catch (e) {
          debugPrint('⚠️ Failed to award fellowship join XP: $e');
        }

        emit(const FellowshipJoined('Successfully joined fellowship!'));
      } else {
        emit(const FellowshipError('Failed to join fellowship'));
      }
    } catch (e) {
      debugPrint('Error joining public fellowship: $e');
      emit(FellowshipError('Failed to join fellowship'));
    }
  }

  /// Directly join a public fellowship by adding the user as a member
  Future<bool> _joinPublicFellowshipDirectly(
    String fellowshipId,
    String userId,
  ) async {
    try {
      // For public fellowships, we can use the acceptFellowshipInvite method
      // since it adds the user to the fellowship and updates their fellowship list
      // This bypasses the join code requirement
      return await inviteFriendUseCase.repository.acceptFellowshipInvite(
        fellowshipId,
        userId,
      );
    } catch (e) {
      debugPrint('Error joining public fellowship directly: $e');
      return false;
    }
  }
}

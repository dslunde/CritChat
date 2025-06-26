import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import 'package:critchat/features/fellowships/domain/usecases/get_fellowships_usecase.dart';
import 'package:critchat/features/fellowships/domain/usecases/create_fellowship_usecase.dart';
import 'package:critchat/features/fellowships/domain/usecases/invite_friend_usecase.dart';
import 'package:critchat/features/fellowships/domain/usecases/get_public_fellowships_usecase.dart';
import 'package:critchat/features/fellowships/domain/usecases/join_fellowship_by_code_usecase.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_event.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_state.dart';

class FellowshipBloc extends Bloc<FellowshipEvent, FellowshipState> {
  final GetFellowshipsUseCase getFellowshipsUseCase;
  final CreateFellowshipUseCase createFellowshipUseCase;
  final InviteFriendUseCase inviteFriendUseCase;
  final GetPublicFellowshipsUseCase getPublicFellowshipsUseCase;
  final JoinFellowshipByCodeUseCase joinFellowshipByCodeUseCase;

  FellowshipBloc({
    required this.getFellowshipsUseCase,
    required this.createFellowshipUseCase,
    required this.inviteFriendUseCase,
    required this.getPublicFellowshipsUseCase,
    required this.joinFellowshipByCodeUseCase,
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
      emit(FellowshipError('Failed to join fellowship'));
    }
  }

  Future<void> _onJoinPublicFellowship(
    JoinPublicFellowship event,
    Emitter<FellowshipState> emit,
  ) async {
    try {
      emit(FellowshipLoading());
      // For public fellowships, we can directly add the user to the fellowship
      // This should be implemented in the repository to handle public fellowship joins
      final success = await getFellowshipsUseCase().then((fellowships) async {
        final fellowship = fellowships.firstWhere(
          (f) => f.id == event.fellowshipId,
        );
        if (fellowship.isPublic &&
            !fellowship.memberIds.contains(event.userId)) {
          // Add user to public fellowship
          return await joinFellowshipByCodeUseCase(
            name: fellowship.name,
            joinCode: '', // Empty join code for public fellowships
            userId: event.userId,
          );
        }
        return false;
      });

      if (success) {
        emit(const FellowshipJoined('Successfully joined fellowship!'));
        // Reload fellowships to show the newly joined fellowship
        add(GetFellowships());
      } else {
        emit(const FellowshipError('Failed to join fellowship'));
      }
    } catch (e) {
      debugPrint('Error joining public fellowship: $e');
      emit(FellowshipError('Failed to join fellowship'));
    }
  }
}

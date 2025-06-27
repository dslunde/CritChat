import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:critchat/features/friends/domain/usecases/get_friends_usecase.dart';
import 'package:critchat/features/friends/domain/usecases/remove_friend_usecase.dart';
import 'friends_event.dart';
import 'friends_state.dart';

class FriendsBloc extends Bloc<FriendsEvent, FriendsState> {
  final GetFriendsUseCase getFriendsUseCase;
  final RemoveFriendUseCase removeFriendUseCase;

  FriendsBloc({
    required this.getFriendsUseCase,
    required this.removeFriendUseCase,
  }) : super(const FriendsInitial()) {
    on<LoadFriends>(_onLoadFriends);
    on<RefreshFriends>(_onRefreshFriends);
    on<SearchFriends>(_onSearchFriends);
    on<AddFriend>(_onAddFriend);
    on<RemoveFriend>(_onRemoveFriend);
  }

  Future<void> _onLoadFriends(
    LoadFriends event,
    Emitter<FriendsState> emit,
  ) async {
    emit(const FriendsLoading());
    try {
      final friends = await getFriendsUseCase();
      if (friends.isEmpty) {
        emit(const FriendsEmpty());
      } else {
        emit(FriendsLoaded(friends));
      }
    } catch (e) {
      emit(FriendsError('Failed to load friends: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshFriends(
    RefreshFriends event,
    Emitter<FriendsState> emit,
  ) async {
    try {
      final friends = await getFriendsUseCase();
      if (friends.isEmpty) {
        emit(const FriendsEmpty());
      } else {
        emit(FriendsLoaded(friends));
      }
    } catch (e) {
      emit(FriendsError('Failed to refresh friends: ${e.toString()}'));
    }
  }

  Future<void> _onSearchFriends(
    SearchFriends event,
    Emitter<FriendsState> emit,
  ) async {
    // TODO: Implement search functionality
    // For now, just reload friends
    add(const LoadFriends());
  }

  Future<void> _onAddFriend(AddFriend event, Emitter<FriendsState> emit) async {
    // TODO: Implement add friend functionality
    // For now, just show a snackbar or do nothing
  }

  Future<void> _onRemoveFriend(
    RemoveFriend event,
    Emitter<FriendsState> emit,
  ) async {
    try {
      await removeFriendUseCase(event.friendId);

      // Reload friends list to reflect the change
      final friends = await getFriendsUseCase();
      if (friends.isEmpty) {
        emit(const FriendsEmpty());
      } else {
        emit(FriendsLoaded(friends));
      }
    } catch (e) {
      emit(FriendsError('Failed to remove friend: ${e.toString()}'));
    }
  }
}

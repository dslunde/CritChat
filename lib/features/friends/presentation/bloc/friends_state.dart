import 'package:equatable/equatable.dart';
import 'package:critchat/features/friends/domain/entities/friend_entity.dart';

abstract class FriendsState extends Equatable {
  const FriendsState();

  @override
  List<Object?> get props => [];
}

class FriendsInitial extends FriendsState {
  const FriendsInitial();
}

class FriendsLoading extends FriendsState {
  const FriendsLoading();
}

class FriendsLoaded extends FriendsState {
  final List<FriendEntity> friends;

  const FriendsLoaded(this.friends);

  @override
  List<Object?> get props => [friends];
}

class FriendsEmpty extends FriendsState {
  const FriendsEmpty();
}

class FriendsError extends FriendsState {
  final String message;

  const FriendsError(this.message);

  @override
  List<Object?> get props => [message];
}

class FriendsSearchResults extends FriendsState {
  final List<FriendEntity> results;
  final String query;

  const FriendsSearchResults(this.results, this.query);

  @override
  List<Object?> get props => [results, query];
}

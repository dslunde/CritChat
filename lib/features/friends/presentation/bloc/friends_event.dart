import 'package:equatable/equatable.dart';

abstract class FriendsEvent extends Equatable {
  const FriendsEvent();

  @override
  List<Object?> get props => [];
}

class LoadFriends extends FriendsEvent {
  const LoadFriends();
}

class RefreshFriends extends FriendsEvent {
  const RefreshFriends();
}

class SearchFriends extends FriendsEvent {
  final String query;

  const SearchFriends(this.query);

  @override
  List<Object?> get props => [query];
}

class AddFriend extends FriendsEvent {
  final String friendId;

  const AddFriend(this.friendId);

  @override
  List<Object?> get props => [friendId];
}

class RemoveFriend extends FriendsEvent {
  final String friendId;

  const RemoveFriend(this.friendId);

  @override
  List<Object?> get props => [friendId];
}

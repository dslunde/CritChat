import '../entities/friend_entity.dart';

abstract class FriendsRepository {
  Future<List<FriendEntity>> getFriends();
  Future<FriendEntity?> getFriendById(String id);
  Future<void> addFriend(String friendId);
  Future<void> removeFriend(String friendId);
  Future<List<FriendEntity>> searchFriends(String query);
}

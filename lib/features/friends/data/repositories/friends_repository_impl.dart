import '../../domain/entities/friend_entity.dart';
import '../../domain/repositories/friends_repository.dart';
import '../datasources/friends_firestore_datasource.dart';

class FriendsRepositoryImpl implements FriendsRepository {
  final FriendsFirestoreDataSource _dataSource;

  FriendsRepositoryImpl(this._dataSource);

  @override
  Future<List<FriendEntity>> getFriends() async {
    return await _dataSource.getFriends();
  }

  @override
  Future<FriendEntity?> getFriendById(String id) async {
    final friends = await _dataSource.getFriends();
    try {
      return friends.firstWhere((friend) => friend.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> addFriend(String friendId) async {
    await _dataSource.sendFriendRequest(friendId);
  }

  @override
  Future<void> removeFriend(String friendId) async {
    await _dataSource.removeFriend(friendId);
  }

  @override
  Future<List<FriendEntity>> searchFriends(String query) async {
    return await _dataSource.searchUsers(query);
  }
}

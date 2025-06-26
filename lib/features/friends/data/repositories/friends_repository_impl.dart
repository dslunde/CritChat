import '../../domain/entities/friend_entity.dart';
import '../../domain/repositories/friends_repository.dart';
import '../datasources/friends_mock_datasource.dart';

class FriendsRepositoryImpl implements FriendsRepository {
  final FriendsMockDataSource dataSource;

  FriendsRepositoryImpl(this.dataSource);

  @override
  Future<List<FriendEntity>> getFriends() async {
    return await dataSource.getFriends();
  }

  @override
  Future<FriendEntity?> getFriendById(String id) async {
    return await dataSource.getFriendById(id);
  }

  @override
  Future<void> addFriend(String friendId) async {
    // TODO: Implement add friend functionality
    throw UnimplementedError('Add friend functionality not yet implemented');
  }

  @override
  Future<void> removeFriend(String friendId) async {
    // TODO: Implement remove friend functionality
    throw UnimplementedError('Remove friend functionality not yet implemented');
  }

  @override
  Future<List<FriendEntity>> searchFriends(String query) async {
    return await dataSource.searchFriends(query);
  }
}

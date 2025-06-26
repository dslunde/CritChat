import '../entities/friend_entity.dart';
import '../repositories/friends_repository.dart';

class GetFriendsUseCase {
  final FriendsRepository repository;

  GetFriendsUseCase(this.repository);

  Future<List<FriendEntity>> call() async {
    return await repository.getFriends();
  }
}

import 'package:critchat/features/friends/domain/repositories/friends_repository.dart';

class RemoveFriendUseCase {
  final FriendsRepository repository;

  RemoveFriendUseCase(this.repository);

  Future<void> call(String friendId) async {
    return await repository.removeFriend(friendId);
  }
}

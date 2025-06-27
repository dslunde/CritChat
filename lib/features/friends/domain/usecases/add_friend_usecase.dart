import 'package:critchat/features/friends/domain/repositories/friends_repository.dart';

class AddFriendUseCase {
  final FriendsRepository repository;

  AddFriendUseCase(this.repository);

  Future<void> call(String friendId) async {
    return await repository.addFriend(friendId);
  }
}

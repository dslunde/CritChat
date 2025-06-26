import 'package:critchat/features/fellowships/domain/repositories/fellowship_repository.dart';

class InviteFriendUseCase {
  final FellowshipRepository repository;

  InviteFriendUseCase({required this.repository});

  Future<bool> call(String fellowshipId, String friendId) {
    return repository.inviteFriendToFellowship(fellowshipId, friendId);
  }
}

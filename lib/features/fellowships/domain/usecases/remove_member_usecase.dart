import 'package:critchat/features/fellowships/domain/repositories/fellowship_repository.dart';

class RemoveMemberUseCase {
  final FellowshipRepository repository;

  RemoveMemberUseCase({required this.repository});

  Future<bool> call(String fellowshipId, String memberId) async {
    return await repository.removeMemberFromFellowship(fellowshipId, memberId);
  }
}

import 'package:critchat/features/fellowships/domain/entities/fellowship_entity.dart';

abstract class FellowshipRepository {
  Future<List<FellowshipEntity>> getFellowships();
  Future<FellowshipEntity> createFellowship({
    required String name,
    required String description,
    required String gameSystem,
    required bool isPublic,
    required String creatorId,
  });
  Future<FellowshipEntity> getFellowshipById(String id);
  Future<bool> inviteFriendToFellowship(String fellowshipId, String friendId);
  Future<bool> acceptFellowshipInvite(String fellowshipId, String userId);
  Future<bool> removeMemberFromFellowship(String fellowshipId, String memberId);
  Future<FellowshipEntity> updateFellowship(FellowshipEntity fellowship);
  Future<bool> deleteFellowship(String fellowshipId);
  Future<List<FellowshipEntity>> getPublicFellowships();
  Future<List<FellowshipEntity>> getUserFellowships(String userId);
}

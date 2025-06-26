import 'package:critchat/features/fellowships/domain/entities/fellowship_entity.dart';
import 'package:critchat/features/fellowships/domain/repositories/fellowship_repository.dart';
import 'package:critchat/features/fellowships/data/datasources/fellowship_firestore_datasource.dart';
import 'package:critchat/features/fellowships/data/models/fellowship_model.dart';
import 'package:critchat/features/auth/data/datasources/auth_firestore_datasource.dart';

class FellowshipRepositoryImpl implements FellowshipRepository {
  final FellowshipFirestoreDataSource _fellowshipDataSource;
  final AuthFirestoreDataSource _authDataSource;

  FellowshipRepositoryImpl({
    required FellowshipFirestoreDataSource fellowshipDataSource,
    required AuthFirestoreDataSource authDataSource,
  }) : _fellowshipDataSource = fellowshipDataSource,
       _authDataSource = authDataSource;

  @override
  Future<List<FellowshipEntity>> getFellowships() async {
    // Get current user's fellowships
    final currentUser = await _authDataSource.getCurrentUser();
    if (currentUser == null) return [];

    return await _fellowshipDataSource.getFellowships(currentUser.fellowships);
  }

  @override
  Future<FellowshipEntity> createFellowship({
    required String name,
    required String description,
    required String gameSystem,
    required bool isPublic,
    required String creatorId,
    String? joinCode,
  }) async {
    final now = DateTime.now();
    final fellowship = FellowshipModel(
      id: '', // Will be set by Firestore
      name: name,
      description: description,
      creatorId: creatorId,
      memberIds: [creatorId], // Creator is automatically a member
      gameSystem: gameSystem,
      isPublic: isPublic,
      joinCode: joinCode,
      createdAt: now,
      updatedAt: now,
    );

    final createdFellowship = await _fellowshipDataSource.createFellowship(
      fellowship,
    );

    // Add fellowship to user's fellowships list
    await _authDataSource.addFellowship(creatorId, createdFellowship.id);

    return createdFellowship;
  }

  @override
  Future<FellowshipEntity> getFellowshipById(String id) async {
    final fellowship = await _fellowshipDataSource.getFellowshipById(id);
    if (fellowship == null) {
      throw Exception('Fellowship not found');
    }
    return fellowship;
  }

  @override
  Future<bool> inviteFriendToFellowship(
    String fellowshipId,
    String friendId,
  ) async {
    try {
      // Get fellowship details for the invitation
      final fellowship = await _fellowshipDataSource.getFellowshipById(
        fellowshipId,
      );
      if (fellowship == null) {
        throw Exception('Fellowship not found');
      }

      // Get inviter details
      final inviter = await _authDataSource.getUserById(fellowship.creatorId);
      final inviterName = inviter?.displayName ?? 'Someone';

      // Send invitation notification (NOT auto-adding to fellowship)
      await _fellowshipDataSource.inviteFriendToFellowship(
        fellowshipId,
        friendId,
        inviterName,
        fellowship.name,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> acceptFellowshipInvite(
    String fellowshipId,
    String userId,
  ) async {
    try {
      // Add user to fellowship
      await _fellowshipDataSource.acceptFellowshipInvite(fellowshipId, userId);

      // Add fellowship to user's fellowships list
      await _authDataSource.addFellowship(userId, fellowshipId);

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> removeMemberFromFellowship(
    String fellowshipId,
    String memberId,
  ) async {
    try {
      // Remove member from fellowship
      await _fellowshipDataSource.removeMember(fellowshipId, memberId);

      // Remove fellowship from member's fellowships list
      await _authDataSource.removeFellowship(memberId, fellowshipId);

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<FellowshipEntity> updateFellowship(FellowshipEntity fellowship) async {
    final fellowshipModel = FellowshipModel.fromEntity(fellowship);
    return await _fellowshipDataSource.updateFellowship(fellowshipModel);
  }

  @override
  Future<bool> deleteFellowship(String fellowshipId) async {
    try {
      // Get fellowship to know which members to update
      final fellowship = await _fellowshipDataSource.getFellowshipById(
        fellowshipId,
      );
      if (fellowship != null) {
        // Remove fellowship from all members' fellowship lists
        for (final memberId in fellowship.memberIds) {
          await _authDataSource.removeFellowship(memberId, fellowshipId);
        }
      }

      // Delete the fellowship
      await _fellowshipDataSource.deleteFellowship(fellowshipId);

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<FellowshipEntity>> getPublicFellowships() async {
    final allFellowships = await _fellowshipDataSource.getAllFellowships();
    return allFellowships.where((f) => f.isPublic).toList();
  }

  @override
  Future<List<FellowshipEntity>> getUserFellowships(String userId) async {
    final user = await _authDataSource.getUserById(userId);
    if (user == null) return [];

    return await _fellowshipDataSource.getFellowships(user.fellowships);
  }

  @override
  Future<FellowshipEntity?> getFellowshipByNameAndJoinCode(
    String name,
    String joinCode,
  ) async {
    final fellowship = await _fellowshipDataSource
        .getFellowshipByNameAndJoinCode(name, joinCode);
    return fellowship;
  }

  @override
  Future<bool> joinFellowshipByCode(
    String name,
    String joinCode,
    String userId,
  ) async {
    try {
      // First, find the fellowship
      final fellowship = await _fellowshipDataSource
          .getFellowshipByNameAndJoinCode(name, joinCode);
      if (fellowship == null) {
        return false; // Fellowship not found or join code incorrect
      }

      // Check if user is already a member
      if (fellowship.memberIds.contains(userId)) {
        return false; // User is already a member
      }

      // Add user to fellowship
      await _fellowshipDataSource.addMember(fellowship.id, userId);

      // Add fellowship to user's fellowships list
      await _authDataSource.addFellowship(userId, fellowship.id);

      return true;
    } catch (e) {
      return false;
    }
  }
}

import '../../domain/entities/fellowship_entity.dart';
import '../../domain/repositories/fellowship_repository.dart';
import '../datasources/fellowship_firestore_datasource.dart';
import '../models/fellowship_model.dart';
import '../../../auth/data/datasources/auth_firestore_datasource.dart';

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
      // Add friend to fellowship
      await _fellowshipDataSource.addMember(fellowshipId, friendId);

      // Add fellowship to friend's fellowships list
      await _authDataSource.addFellowship(friendId, fellowshipId);

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
}

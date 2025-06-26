import '../../domain/entities/fellowship_entity.dart';
import '../../domain/repositories/fellowship_repository.dart';
import '../datasources/fellowship_mock_datasource.dart';

class FellowshipRepositoryImpl implements FellowshipRepository {
  final FellowshipMockDataSource dataSource;

  FellowshipRepositoryImpl({required this.dataSource});

  @override
  Future<List<FellowshipEntity>> getFellowships() {
    return dataSource.getFellowships();
  }

  @override
  Future<FellowshipEntity> createFellowship({
    required String name,
    required String description,
    required String gameSystem,
    required bool isPublic,
    required String creatorId,
  }) {
    return dataSource.createFellowship(
      name: name,
      description: description,
      gameSystem: gameSystem,
      isPublic: isPublic,
      creatorId: creatorId,
    );
  }

  @override
  Future<FellowshipEntity> getFellowshipById(String id) async {
    final fellowship = await dataSource.getFellowshipById(id);
    if (fellowship == null) {
      throw Exception('Fellowship not found');
    }
    return fellowship;
  }

  @override
  Future<bool> inviteFriendToFellowship(String fellowshipId, String friendId) {
    return dataSource.inviteFriendToFellowship(fellowshipId, friendId);
  }

  @override
  Future<bool> removeMemberFromFellowship(
    String fellowshipId,
    String memberId,
  ) {
    return dataSource.removeMemberFromFellowship(fellowshipId, memberId);
  }

  @override
  Future<FellowshipEntity> updateFellowship(FellowshipEntity fellowship) {
    // For now, return the fellowship as-is since mock doesn't support full updates
    // In a real implementation, this would update the fellowship in the data source
    return Future.value(fellowship);
  }

  @override
  Future<bool> deleteFellowship(String fellowshipId) {
    return dataSource.deleteFellowship(fellowshipId);
  }

  @override
  Future<List<FellowshipEntity>> getPublicFellowships() {
    return dataSource.getPublicFellowships();
  }

  @override
  Future<List<FellowshipEntity>> getUserFellowships(String userId) {
    return dataSource.getUserFellowships(userId);
  }
}

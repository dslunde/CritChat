import '../models/fellowship_model.dart';

class FellowshipMockDataSource {
  final List<FellowshipModel> _fellowships = [
    FellowshipModel(
      id: 'fellowship1',
      name: 'The Brave Adventurers',
      description:
          'A fellowship of heroes seeking glory and treasure in the realm of Faerûn. We meet weekly for epic adventures and memorable storytelling.',
      creatorId: '1',
      memberIds: ['1', '2', '3'],
      gameSystem: 'D&D 5e',
      isPublic: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    FellowshipModel(
      id: 'fellowship2',
      name: 'Shadowrun Seattle',
      description:
          'Corporate espionage and cyberpunk action in the sixth world. Looking for experienced runners only.',
      creatorId: '4',
      memberIds: ['4', '5'],
      gameSystem: 'Shadowrun 6e',
      isPublic: false,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    FellowshipModel(
      id: 'fellowship3',
      name: 'Call of Cthulhu Mystery Society',
      description:
          'Investigating cosmic horrors and ancient mysteries in 1920s New England. Sanity not guaranteed.',
      creatorId: '6',
      memberIds: ['6', '7', '8', '9'],
      gameSystem: 'Call of Cthulhu 7e',
      isPublic: true,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    FellowshipModel(
      id: 'fellowship4',
      name: 'Pathfinder Explorers',
      description:
          'Exploring the inner sea region with a focus on character development and tactical combat.',
      creatorId: '2',
      memberIds: ['2', '10'],
      gameSystem: 'Pathfinder 2e',
      isPublic: true,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    FellowshipModel(
      id: 'fellowship5',
      name: 'Vampire: The Masquerade',
      description:
          'Political intrigue and personal horror in modern nights. Embrace the darkness.',
      creatorId: '3',
      memberIds: ['3', '11', '12'],
      gameSystem: 'Vampire: The Masquerade 5e',
      isPublic: false,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  Future<List<FellowshipModel>> getFellowships() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_fellowships);
  }

  Future<FellowshipModel> createFellowship({
    required String name,
    required String description,
    required String gameSystem,
    required bool isPublic,
    required String creatorId,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final newFellowship = FellowshipModel(
      id: 'fellowship_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      creatorId: creatorId,
      memberIds: [creatorId], // Creator is automatically a member
      gameSystem: gameSystem,
      isPublic: isPublic,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _fellowships.add(newFellowship);
    return newFellowship;
  }

  Future<FellowshipModel?> getFellowshipById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _fellowships.firstWhere((fellowship) => fellowship.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<bool> inviteFriendToFellowship(
    String fellowshipId,
    String friendId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final fellowshipIndex = _fellowships.indexWhere(
      (f) => f.id == fellowshipId,
    );
    if (fellowshipIndex == -1) return false;

    final fellowship = _fellowships[fellowshipIndex];
    if (fellowship.memberIds.contains(friendId)) {
      return false; // Already a member
    }

    final updatedFellowship = fellowship.copyWith(
      memberIds: [...fellowship.memberIds, friendId],
      updatedAt: DateTime.now(),
    );

    _fellowships[fellowshipIndex] = updatedFellowship;
    return true;
  }

  Future<bool> removeMemberFromFellowship(
    String fellowshipId,
    String memberId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final fellowshipIndex = _fellowships.indexWhere(
      (f) => f.id == fellowshipId,
    );
    if (fellowshipIndex == -1) return false;

    final fellowship = _fellowships[fellowshipIndex];
    if (!fellowship.memberIds.contains(memberId)) return false; // Not a member
    if (fellowship.creatorId == memberId) return false; // Can't remove creator

    final updatedMemberIds = fellowship.memberIds
        .where((id) => id != memberId)
        .toList();
    final updatedFellowship = fellowship.copyWith(
      memberIds: updatedMemberIds,
      updatedAt: DateTime.now(),
    );

    _fellowships[fellowshipIndex] = updatedFellowship;
    return true;
  }

  Future<bool> deleteFellowship(String fellowshipId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final initialLength = _fellowships.length;
    _fellowships.removeWhere((f) => f.id == fellowshipId);
    return _fellowships.length < initialLength;
  }

  Future<List<FellowshipModel>> getPublicFellowships() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _fellowships.where((f) => f.isPublic).toList();
  }

  Future<List<FellowshipModel>> getUserFellowships(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _fellowships.where((f) => f.memberIds.contains(userId)).toList();
  }
}

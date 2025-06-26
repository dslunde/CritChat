import '../models/friend_model.dart';

class FriendsMockDataSource {
  static final List<FriendModel> _mockFriends = [
    FriendModel(
      id: '1',
      displayName: 'Sarah the Ranger',
      email: 'sarah@example.com',
      bio: 'Level 8 Ranger who loves exploring forgotten ruins',
      isOnline: true,
      preferredSystems: ['D&D 5e', 'Pathfinder'],
      experienceLevel: 'experienced',
      totalXp: 2840,
    ),
    FriendModel(
      id: '2',
      displayName: 'Marcus Ironbeard',
      email: 'marcus@example.com',
      bio: 'Dwarf Fighter with a passion for crafting and battle',
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
      preferredSystems: ['D&D 5e', 'Call of Cthulhu'],
      experienceLevel: 'veteran',
      totalXp: 4200,
    ),
    FriendModel(
      id: '3',
      displayName: 'Luna Spellweaver',
      email: 'luna@example.com',
      bio: 'Elven Wizard specializing in illusion magic',
      isOnline: true,
      preferredSystems: ['D&D 5e', 'World of Darkness'],
      experienceLevel: 'intermediate',
      totalXp: 1950,
    ),
    FriendModel(
      id: '4',
      displayName: 'Thorak the Bold',
      email: 'thorak@example.com',
      bio: 'Barbarian who charges first and asks questions later',
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(days: 1)),
      preferredSystems: ['D&D 5e', 'Warhammer'],
      experienceLevel: 'beginner',
      totalXp: 680,
    ),
    FriendModel(
      id: '5',
      displayName: 'Zara Nightwhisper',
      email: 'zara@example.com',
      bio: 'Rogue with a mysterious past and nimble fingers',
      isOnline: true,
      preferredSystems: ['D&D 5e', 'Cyberpunk'],
      experienceLevel: 'experienced',
      totalXp: 3100,
    ),
  ];

  Future<List<FriendModel>> getFriends() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_mockFriends);
  }

  Future<FriendModel?> getFriendById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _mockFriends.firstWhere((friend) => friend.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<FriendModel>> searchFriends(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (query.isEmpty) return [];

    return _mockFriends
        .where(
          (friend) =>
              friend.displayName.toLowerCase().contains(query.toLowerCase()) ||
              friend.email.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }
}

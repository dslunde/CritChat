class FellowshipEntity {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final List<String> memberIds;
  final String gameSystem;
  final bool isPublic;
  final String? joinCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FellowshipEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.memberIds,
    required this.gameSystem,
    required this.isPublic,
    this.joinCode,
    required this.createdAt,
    required this.updatedAt,
  });

  bool isCreator(String userId) => creatorId == userId;

  bool isMember(String userId) => memberIds.contains(userId);

  int get memberCount => memberIds.length;

  FellowshipEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? creatorId,
    List<String>? memberIds,
    String? gameSystem,
    bool? isPublic,
    String? joinCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FellowshipEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      memberIds: memberIds ?? this.memberIds,
      gameSystem: gameSystem ?? this.gameSystem,
      isPublic: isPublic ?? this.isPublic,
      joinCode: joinCode ?? this.joinCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FellowshipEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          creatorId == other.creatorId &&
          memberIds.toString() == other.memberIds.toString() &&
          gameSystem == other.gameSystem &&
          isPublic == other.isPublic &&
          joinCode == other.joinCode;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      creatorId.hashCode ^
      memberIds.hashCode ^
      gameSystem.hashCode ^
      isPublic.hashCode ^
      joinCode.hashCode;

  @override
  String toString() =>
      'FellowshipEntity('
      'id: $id, '
      'name: $name, '
      'description: $description, '
      'creatorId: $creatorId, '
      'memberIds: $memberIds, '
      'gameSystem: $gameSystem, '
      'isPublic: $isPublic, '
      'joinCode: $joinCode, '
      'createdAt: $createdAt, '
      'updatedAt: $updatedAt'
      ')';
}

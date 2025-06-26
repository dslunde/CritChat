import 'package:critchat/features/fellowships/domain/entities/fellowship_entity.dart';

class FellowshipModel extends FellowshipEntity {
  const FellowshipModel({
    required super.id,
    required super.name,
    required super.description,
    required super.creatorId,
    required super.memberIds,
    required super.gameSystem,
    required super.isPublic,
    required super.createdAt,
    required super.updatedAt,
  });

  factory FellowshipModel.fromEntity(FellowshipEntity entity) {
    return FellowshipModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      creatorId: entity.creatorId,
      memberIds: entity.memberIds,
      gameSystem: entity.gameSystem,
      isPublic: entity.isPublic,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory FellowshipModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    return FellowshipModel(
      id: docId ?? json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      creatorId: json['creatorId'] as String,
      memberIds: List<String>.from(json['memberIds'] as List),
      gameSystem: json['gameSystem'] as String,
      isPublic: json['isPublic'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'memberIds': memberIds,
      'gameSystem': gameSystem,
      'isPublic': isPublic,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  FellowshipModel copyWith({
    String? id,
    String? name,
    String? description,
    String? creatorId,
    List<String>? memberIds,
    String? gameSystem,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FellowshipModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      memberIds: memberIds ?? this.memberIds,
      gameSystem: gameSystem ?? this.gameSystem,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

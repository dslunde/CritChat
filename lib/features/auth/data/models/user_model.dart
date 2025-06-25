import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.photoUrl,
    super.bio,
    super.preferredSystems,
    super.experienceLevel,
    super.totalXp,
    super.joinedGroups,
    super.createdAt,
    super.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      id: id,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      bio: json['bio'] as String?,
      preferredSystems: List<String>.from(json['preferredSystems'] ?? []),
      experienceLevel: json['experienceLevel'] as String?,
      totalXp: json['totalXp'] as int? ?? 0,
      joinedGroups: List<String>.from(json['joinedGroups'] ?? []),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      lastLogin: json['lastLogin'] != null
          ? (json['lastLogin'] as Timestamp).toDate()
          : null,
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      bio: entity.bio,
      preferredSystems: entity.preferredSystems,
      experienceLevel: entity.experienceLevel,
      totalXp: entity.totalXp,
      joinedGroups: entity.joinedGroups,
      createdAt: entity.createdAt,
      lastLogin: entity.lastLogin,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bio': bio,
      'preferredSystems': preferredSystems,
      'experienceLevel': experienceLevel,
      'totalXp': totalXp,
      'joinedGroups': joinedGroups,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? bio,
    List<String>? preferredSystems,
    String? experienceLevel,
    int? totalXp,
    List<String>? joinedGroups,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      preferredSystems: preferredSystems ?? this.preferredSystems,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      totalXp: totalXp ?? this.totalXp,
      joinedGroups: joinedGroups ?? this.joinedGroups,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}

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
    super.friends,
    super.fellowships,
    super.joinedGroups,
    super.createdAt,
    super.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    try {
      return UserModel(
        id: id,
        email: json['email'] as String? ?? '',
        displayName: json['displayName'] as String?,
        photoUrl: json['photoUrl'] as String?,
        bio: json['bio'] as String?,
        preferredSystems: _safeStringList(json['preferredSystems']),
        experienceLevel: json['experienceLevel'] as String?,
        totalXp: _safeInt(json['totalXp']),
        friends: _safeStringList(json['friends']),
        fellowships: _safeStringList(json['fellowships']),
        joinedGroups: _safeStringList(json['joinedGroups']),
        createdAt: _safeDateTime(json['createdAt']),
        lastLogin: _safeDateTime(json['lastLogin']),
      );
    } catch (e) {
      throw Exception('Failed to parse user data: $e');
    }
  }

  static List<String> _safeStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _safeDateTime(dynamic value) {
    try {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    } catch (e) {
      return null;
    }
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
      friends: entity.friends,
      fellowships: entity.fellowships,
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
      'friends': friends,
      'fellowships': fellowships,
      'joinedGroups': joinedGroups,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
    };
  }

  @override
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? bio,
    List<String>? preferredSystems,
    String? experienceLevel,
    int? totalXp,
    List<String>? friends,
    List<String>? fellowships,
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
      friends: friends ?? this.friends,
      fellowships: fellowships ?? this.fellowships,
      joinedGroups: joinedGroups ?? this.joinedGroups,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
